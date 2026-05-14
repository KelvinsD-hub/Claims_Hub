const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');
const { PDFDocument, rgb, StandardFonts } = require('pdf-lib');
const crypto = require('crypto');
const https = require('https');
const cors = require('cors')({ origin: true });

admin.initializeApp();

// ─── Shared helpers ───────────────────────────────────────────────────────────

function createTransporter() {
  return nodemailer.createTransport({
    host: 'smtp.hostinger.com',
    port: 587,
    secure: false,
    auth: {
      user: 'info@claimshub.online',
      pass: process.env.HOSTINGER_EMAIL_PASS.trim(),
    },
    tls: { rejectUnauthorized: false },
  });
}

async function storePdf(claimId, filename, pdfBytes) {
  const bucket = admin.storage().bucket();
  const filePath = `claims/${claimId}/${filename}`;
  const file = bucket.file(filePath);
  const downloadToken = crypto.randomUUID();

  await file.save(Buffer.from(pdfBytes), {
    metadata: {
      contentType: 'application/pdf',
      metadata: { firebaseStorageDownloadTokens: downloadToken },
    },
  });

  return (
    `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/` +
    `${encodeURIComponent(filePath)}?alt=media&token=${downloadToken}`
  );
}

function formatDate() {
  return new Date().toLocaleDateString('en-GB', {
    day: 'numeric', month: 'long', year: 'numeric',
  });
}

// ─── LOA PDF Builder ──────────────────────────────────────────────────────────
// Personal authorization from the claimant appointing Claims Assist as their
// legal representative. Signed by the client.

async function buildLoaPdf(data, claimId) {
  const pdfDoc = await PDFDocument.create();
  const bold = await pdfDoc.embedFont(StandardFonts.HelveticaBold);
  const reg = await pdfDoc.embedFont(StandardFonts.Helvetica);

  const page = pdfDoc.addPage([595, 842]);
  const navy = rgb(0, 0.157, 0.333);
  const grey = rgb(0.4, 0.4, 0.4);
  const ltGrey = rgb(0.8, 0.8, 0.8);
  const black = rgb(0, 0, 0);
  const white = rgb(1, 1, 1);

  const today = formatDate();
  const clientName = data.full_name || 'The Passenger';
  const pnr = data.pnr || data.booking_reference || 'N/A';

  // Header band
  page.drawRectangle({ x: 0, y: 792, width: 595, height: 50, color: navy });
  page.drawText('CLAIMS ASSIST LIMITED', { x: 40, y: 812, size: 14, font: bold, color: white });
  page.drawText('Legal Department  |  info@claimshub.online', { x: 40, y: 797, size: 8, font: reg, color: ltGrey });

  let y = 752;

  // Title
  page.drawText('LETTER OF AUTHORITY', { x: 40, y, size: 16, font: bold, color: navy });
  y -= 16;
  page.drawText(`Date: ${today}`, { x: 40, y, size: 10, font: reg, color: grey });
  y -= 8;
  page.drawLine({ start: { x: 40, y }, end: { x: 555, y }, thickness: 0.5, color: ltGrey });

  // To block
  y -= 18;
  page.drawText('To:', { x: 40, y, size: 11, font: bold, color: black });
  y -= 15;
  page.drawText('Legal / Customer Relations Department', { x: 40, y, size: 11, font: reg, color: black });
  y -= 15;
  page.drawText(data.airline_name || 'The Airline', { x: 40, y, size: 11, font: bold, color: black });

  // Opening paragraph
  y -= 22;
  page.drawText(`I, ${clientName}, hereby appoint CLAIMS ASSIST LIMITED as my duly authorised`, { x: 40, y, size: 10.5, font: reg, color: black });
  y -= 14;
  page.drawText('representative to act on my behalf in all matters relating to my flight', { x: 40, y, size: 10.5, font: reg, color: black });
  y -= 14;
  page.drawText('compensation claim detailed below:', { x: 40, y, size: 10.5, font: reg, color: black });

  // Flight details
  y -= 22;
  page.drawText('FLIGHT DETAILS', { x: 40, y, size: 10.5, font: bold, color: navy });
  y -= 5;
  page.drawLine({ start: { x: 40, y }, end: { x: 555, y }, thickness: 0.5, color: ltGrey });
  y -= 16;

  for (const [label, value] of [
    ['PNR / Booking Reference', pnr],
    ['Flight Number', data.flight_number || 'N/A'],
    ['Date of Travel', data.flight_date || 'N/A'],
    ['Route', `${data.departure || 'N/A'} to ${data.destination || 'N/A'}`],
    ['Duration of Delay', data.duration_of_delay || 'N/A'],
    ['Reason for Claim', data.claims_reason || 'N/A'],
    ['Compensation Sought', data.claims_amount || 'To be assessed'],
  ]) {
    page.drawText(`${label}:`, { x: 40, y, size: 10, font: bold, color: grey });
    page.drawText(String(value), { x: 225, y, size: 10, font: reg, color: black });
    y -= 16;
  }

  // Authorisation scope
  y -= 8;
  page.drawText('I authorise Claims Assist Limited to:', { x: 40, y, size: 10.5, font: reg, color: black });
  y -= 14;
  for (const pt of [
    '1.  Correspond with and make representations to the airline on my behalf;',
    '2.  Negotiate and accept any settlement offer made in respect of this claim;',
    '3.  Commence any legal or regulatory proceedings as may be necessary; and',
    '4.  Receive any compensation or settlement payment on my behalf.',
  ]) {
    page.drawText(pt, { x: 50, y, size: 10, font: reg, color: black });
    y -= 14;
  }

  // Payment direction
  y -= 8;
  page.drawText('All compensation is to be paid directly to Claims Assist Limited on my behalf:', { x: 40, y, size: 10.5, font: reg, color: black });
  y -= 16;
  for (const [label, value] of [
    ['Account Name', 'CLAIMS ASSIST LTD'],
    ['Bank', 'First City Monument Bank (FCMB)'],
    ['Account Number', '2008264829'],
  ]) {
    page.drawText(`${label}:`, { x: 55, y, size: 10, font: bold, color: grey });
    page.drawText(value, { x: 225, y, size: 10, font: bold, color: navy });
    y -= 16;
  }

  // Terms confirmation
  y -= 8;
  const termsPrefix = data.terms_accepted === true ? '[Agreed]' : '[     ]';
  page.drawText(
    `${termsPrefix}  I have read and accepted the Terms and Conditions of engagement with`,
    { x: 40, y, size: 10, font: reg, color: black }
  );
  y -= 13;
  page.drawText(
    '             Claims Assist Limited, including the no-win, no-fee arrangement.',
    { x: 40, y, size: 10, font: reg, color: black }
  );

  // Signature section
  y -= 22;
  page.drawLine({ start: { x: 40, y }, end: { x: 555, y }, thickness: 0.5, color: ltGrey });
  y -= 16;
  page.drawText('Signed by Passenger:', { x: 40, y, size: 11, font: bold, color: black });
  y -= 8;

  if (data.signature) {
    try {
      const pngBytes = Buffer.from(data.signature, 'base64');
      const sigImage = await pdfDoc.embedPng(pngBytes);
      page.drawImage(sigImage, { x: 40, y: y - 90, width: 190, height: 90 });
      y -= 110;
    } catch (_) {
      page.drawText('(Signature could not be rendered)', { x: 40, y, size: 10, font: reg, color: grey });
      y -= 16;
    }
  } else {
    page.drawText('(No digital signature provided)', { x: 40, y, size: 10, font: reg, color: grey });
    y -= 16;
  }

  y -= 10;
  page.drawText(`Name:   ${clientName}`, { x: 40, y, size: 10, font: reg, color: black });
  y -= 14;
  page.drawText(`Date:   ${today}`, { x: 40, y, size: 10, font: reg, color: black });

  return pdfDoc.save();
}

// ─── Formal Demand Letter PDF Builder ────────────────────────────────────────
// Legal demand letter from Claims Assist to the airline, citing NCAR 2023 Part 19.
// Includes payment details and escalation consequences.

async function buildDemandLetterPdf(data, claimId) {
  const pdfDoc = await PDFDocument.create();
  const bold = await pdfDoc.embedFont(StandardFonts.HelveticaBold);
  const reg = await pdfDoc.embedFont(StandardFonts.Helvetica);

  const page = pdfDoc.addPage([595, 842]);
  const navy = rgb(0, 0.157, 0.333);
  const grey = rgb(0.4, 0.4, 0.4);
  const ltGrey = rgb(0.8, 0.8, 0.8);
  const black = rgb(0, 0, 0);
  const white = rgb(1, 1, 1);

  const today = formatDate();
  const clientName = data.full_name || 'The Passenger';
  const pnr = data.pnr || data.booking_reference || 'N/A';
  const rawAmount = data.claims_amount;
  const amountText = rawAmount || 'the applicable statutory amount';

  // Header band
  page.drawRectangle({ x: 0, y: 792, width: 595, height: 50, color: navy });
  page.drawText('CLAIMS ASSIST LIMITED', { x: 40, y: 818, size: 14, font: bold, color: white });
  page.drawText('Legal Department  |  info@claimshub.online', { x: 40, y: 797, size: 8, font: reg, color: ltGrey });

  let y = 762;
  page.drawText(`Ref: CA/${claimId}`, { x: 40, y, size: 9, font: reg, color: grey });
  y -= 13;
  page.drawText(`Date: ${today}`, { x: 40, y, size: 9, font: reg, color: grey });

  y -= 18;
  page.drawText('To:', { x: 40, y, size: 10.5, font: bold, color: black });
  y -= 14;
  page.drawText('Legal / Customer Relations Department', { x: 40, y, size: 10.5, font: reg, color: black });
  y -= 14;
  page.drawText(data.airline_name || 'The Airline', { x: 40, y, size: 10.5, font: bold, color: black });
  y -= 14;
  page.drawText('BY EMAIL', { x: 40, y, size: 8.5, font: bold, color: grey });

  y -= 18;
  page.drawLine({ start: { x: 40, y }, end: { x: 555, y }, thickness: 1.2, color: navy });
  y -= 14;
  page.drawText('FORMAL DEMAND FOR STATUTORY COMPENSATION — NCAR 2023 PART 19', {
    x: 40, y, size: 11, font: bold, color: navy,
  });
  y -= 4;
  page.drawLine({ start: { x: 40, y }, end: { x: 555, y }, thickness: 1.2, color: navy });

  y -= 18;
  page.drawText('Dear Legal Department,', { x: 40, y, size: 10.5, font: reg, color: black });

  y -= 16;
  page.drawText(`We act on behalf of our client, ${clientName} ("the Passenger"), pursuant to a`, {
    x: 40, y, size: 10, font: reg, color: black,
  });
  y -= 13;
  page.drawText('Letter of Authority signed today, a copy of which is enclosed herewith.', {
    x: 40, y, size: 10, font: reg, color: black,
  });

  // Particulars
  y -= 18;
  page.drawText('PARTICULARS OF CLAIM', { x: 40, y, size: 10.5, font: bold, color: navy });
  y -= 5;
  page.drawLine({ start: { x: 40, y }, end: { x: 555, y }, thickness: 0.5, color: ltGrey });
  y -= 14;

  for (const [label, value] of [
    ['Passenger', clientName],
    ['PNR / Booking Reference', pnr],
    ['Flight Number', data.flight_number || 'N/A'],
    ['Date of Travel', data.flight_date || 'N/A'],
    ['Route', `${data.departure || 'N/A'} to ${data.destination || 'N/A'}`],
    ['Duration of Delay', data.duration_of_delay || 'N/A'],
    ['Compensation Sought', amountText],
  ]) {
    page.drawText(`${label}:`, { x: 40, y, size: 10, font: bold, color: grey });
    page.drawText(String(value), { x: 225, y, size: 10, font: reg, color: black });
    y -= 15;
  }

  // Legal basis
  y -= 8;
  page.drawText('THE LAW', { x: 40, y, size: 10.5, font: bold, color: navy });
  y -= 5;
  page.drawLine({ start: { x: 40, y }, end: { x: 555, y }, thickness: 0.5, color: ltGrey });
  y -= 13;

  for (const line of [
    'Under Part 19 of the Nigerian Civil Aviation Regulations (NCAR) 2023, passengers are',
    'entitled to statutory compensation when a flight is delayed or cancelled for reasons',
    'within the airline\'s control. The circumstances giving rise to this claim do not',
    'constitute an extraordinary circumstance exempting your airline from liability.',
  ]) {
    page.drawText(line, { x: 40, y, size: 10, font: reg, color: black });
    y -= 13;
  }

  // Demand
  y -= 8;
  page.drawText('DEMAND', { x: 40, y, size: 10.5, font: bold, color: navy });
  y -= 5;
  page.drawLine({ start: { x: 40, y }, end: { x: 555, y }, thickness: 0.5, color: ltGrey });
  y -= 13;

  page.drawText(`We hereby formally demand payment of ${amountText} within`, {
    x: 40, y, size: 10, font: bold, color: black,
  });
  y -= 13;
  page.drawText('FOURTEEN (14) DAYS of receipt of this letter, to the following account:', {
    x: 40, y, size: 10, font: reg, color: black,
  });
  y -= 15;

  for (const [label, value] of [
    ['Account Name', 'CLAIMS ASSIST LTD'],
    ['Bank', 'First City Monument Bank (FCMB)'],
    ['Account Number', '2008264829'],
    ['Payment Reference', `CA/${claimId}`],
  ]) {
    page.drawText(`${label}:`, { x: 55, y, size: 10, font: bold, color: grey });
    page.drawText(value, { x: 225, y, size: 10, font: bold, color: navy });
    y -= 15;
  }

  // Consequences
  y -= 8;
  page.drawText('CONSEQUENCE OF NON-COMPLIANCE', { x: 40, y, size: 10.5, font: bold, color: navy });
  y -= 5;
  page.drawLine({ start: { x: 40, y }, end: { x: 555, y }, thickness: 0.5, color: ltGrey });
  y -= 13;

  page.drawText('Failure to settle within 14 days will, without further notice, result in:', {
    x: 40, y, size: 10, font: reg, color: black,
  });
  y -= 13;
  for (const line of [
    '(a)  A formal complaint to the Nigerian Civil Aviation Authority (NCAA);',
    '(b)  A formal complaint to the Federal Competition and Consumer Protection',
    '      Commission (FCCPC); and',
    '(c)  The commencement of proceedings in the Federal High Court of Nigeria for',
    '      the full statutory amount, plus interest and legal costs.',
  ]) {
    page.drawText(line, { x: 50, y, size: 10, font: reg, color: black });
    y -= 13;
  }

  y -= 10;
  page.drawText(
    'This letter is written without prejudice to all other rights and remedies available to our client.',
    { x: 40, y, size: 9, font: reg, color: grey }
  );

  y -= 22;
  page.drawText('Yours faithfully,', { x: 40, y, size: 10.5, font: reg, color: black });
  y -= 24;
  page.drawText('CLAIMS ASSIST LEGAL TEAM', { x: 40, y, size: 11, font: bold, color: navy });
  y -= 14;
  page.drawText('info@claimshub.online', { x: 40, y, size: 10, font: reg, color: navy });

  return pdfDoc.save();
}

// ─── 1. CORS Proxy ────────────────────────────────────────────────────────────

exports.corsProxy = functions
  .runWith({ minInstances: 1, timeoutSeconds: 15 })
  .https.onRequest((req, res) => {
    cors(req, res, () => {
      const url = req.query.url || req.body.url;
      if (!url) return res.status(403).send('URL is empty.');
      https.get(url, (resp) => {
        res.setHeader('content-type', resp.headers['content-type'] || 'image/jpeg');
        resp.pipe(res);
      });
    });
  });

// ─── 2. On User Deleted ───────────────────────────────────────────────────────

exports.onUserDeleted = functions.auth.user().onDelete(async (user) => {
  await admin.firestore().doc(`users/${user.uid}`).delete().catch(() => {});
});

// ─── 3. On Claim Created → Send evidence form link to client ─────────────────

exports.onClaimCreatedSendEmail = functions
  .runWith({ secrets: ['HOSTINGER_EMAIL_PASS'] })
  .firestore.document('claims/{claimId}')
  .onCreate(async (snapshot, context) => {
    const data = snapshot.data();
    if (data.claim_status !== 'Details Pending') return null;

    const claimId = context.params.claimId;
    const evidenceUrl =
      `https://claimshub.online/evidenceForm` +
      `?claimRef=claims%2F${claimId}&token=${data.secure_token}`;

    const mailOptions = {
      from: '"Claims Assist" <info@claimshub.online>',
      to: data.client_email,
      subject: 'Action Required: Submit Your Flight Claim Evidence',
      html: `
        <div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;color:#333">
          <div style="background:#002855;padding:24px 32px;border-radius:8px 8px 0 0">
            <h1 style="color:#fff;margin:0;font-size:22px">Claims Assist</h1>
          </div>
          <div style="padding:32px;border:1px solid #e0e0e0;border-top:none;border-radius:0 0 8px 8px">
            <h2>Hello ${data.full_name || 'Customer'},</h2>
            <p>Your flight compensation claim has been registered. To proceed, please submit
               your evidence using the button below.</p>
            <p style="text-align:center;margin:32px 0">
              <a href="${evidenceUrl}"
                 style="background:#002855;color:#fff;padding:14px 28px;
                        border-radius:6px;text-decoration:none;font-weight:bold;font-size:15px">
                Submit My Evidence
              </a>
            </p>
            <p style="font-size:13px;color:#666">
              Or copy this link:<br/>
              <a href="${evidenceUrl}">${evidenceUrl}</a>
            </p>
            <hr style="border:none;border-top:1px solid #e0e0e0;margin:24px 0"/>
            <p style="font-size:13px;color:#999">
              Questions? Email us at
              <a href="mailto:info@claimshub.online">info@claimshub.online</a>
            </p>
          </div>
        </div>
      `,
    };

    try {
      await createTransporter().sendMail(mailOptions);
    } catch (e) {
      console.error('[onClaimCreatedSendEmail]', e.message);
    }
    return null;
  });

// ─── 4. On Trigger Airline Email → Generate LOA + Demand Letter, email airline ─

exports.onTriggerAirlineEmail = functions
  .runWith({ secrets: ['HOSTINGER_EMAIL_PASS'], timeoutSeconds: 120 })
  .firestore.document('claims/{claimId}')
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const prevData = change.before.data();

    if (!(newData.trigger_airline_email === true && prevData.trigger_airline_email !== true)) {
      return null;
    }

    const claimId = context.params.claimId;
    const clientName = newData.full_name || 'Client';
    const safeName = clientName.replace(/\s+/g, '_');

    // Generate both PDFs in parallel
    const [loaBytes, demandBytes] = await Promise.all([
      buildLoaPdf(newData, claimId),
      buildDemandLetterPdf(newData, claimId),
    ]);

    // Store both in Firebase Storage in parallel
    const [loaUrl, demandUrl] = await Promise.all([
      storePdf(claimId, `LOA_${claimId}.pdf`, loaBytes),
      storePdf(claimId, `DemandLetter_${claimId}.pdf`, demandBytes),
    ]);

    const airlineEmail = newData.airline_email_selection || newData.airline_email;
    const amountDisplay = newData.claims_amount || 'the applicable statutory amount';

    await createTransporter().sendMail({
      from: '"Claims Assist Legal" <info@claimshub.online>',
      to: airlineEmail,
      subject: `FORMAL DEMAND: ${clientName} | Flight ${newData.flight_number || 'N/A'} | Ref: CA/${claimId}`,
      html: `
        <div style="font-family:'Times New Roman',serif;line-height:1.8;max-width:700px;color:#111">
          <table width="100%" cellpadding="0" cellspacing="0">
            <tr>
              <td style="background:#002855;padding:20px 28px">
                <span style="color:#fff;font-size:18px;font-weight:bold;font-family:Arial">CLAIMS ASSIST LIMITED</span><br/>
                <span style="color:#aac4e0;font-size:11px;font-family:Arial">Legal Department &nbsp;|&nbsp; info@claimshub.online</span>
              </td>
            </tr>
          </table>

          <div style="padding:28px 0">
            <p style="margin:0 0 4px"><strong>Ref:</strong> CA/${claimId}</p>
            <p style="margin:0 0 20px;color:#555;font-size:13px">${new Date().toLocaleDateString('en-GB', { day: 'numeric', month: 'long', year: 'numeric' })}</p>

            <p style="margin:0 0 4px"><strong>To:</strong></p>
            <p style="margin:0 0 4px">Legal / Customer Relations Department</p>
            <p style="margin:0 0 20px;font-weight:bold">${newData.airline_name || 'The Airline'}</p>

            <p style="color:#555;font-size:11px;margin:0 0 24px">BY EMAIL</p>

            <hr style="border:none;border-top:2px solid #002855;margin:0 0 8px"/>
            <p style="font-size:15px;font-weight:bold;color:#002855;margin:0 0 8px">
              FORMAL DEMAND FOR STATUTORY COMPENSATION — NCAR 2023 PART 19
            </p>
            <hr style="border:none;border-top:2px solid #002855;margin:0 0 24px"/>

            <p>Dear Legal Department,</p>

            <p>
              We act on behalf of our client, <strong>${clientName}</strong>
              ("the Passenger"), pursuant to a duly executed Letter of Authority,
              a copy of which is attached to this email.
            </p>

            <table width="100%" cellpadding="6" cellspacing="0"
                   style="border-collapse:collapse;margin:16px 0;font-size:13px">
              <tr style="background:#f2f5f9">
                <td colspan="2" style="padding:8px 10px;font-weight:bold;color:#002855;
                    border-bottom:1px solid #c8d6e5;font-size:13px">PARTICULARS OF CLAIM</td>
              </tr>
              ${[
                ['Passenger', clientName],
                ['PNR / Booking Reference', newData.pnr || newData.booking_reference || 'N/A'],
                ['Flight Number', newData.flight_number || 'N/A'],
                ['Date of Travel', newData.flight_date || 'N/A'],
                ['Route', `${newData.departure || 'N/A'} &rarr; ${newData.destination || 'N/A'}`],
                ['Duration of Delay', newData.duration_of_delay || 'N/A'],
                ['Compensation Sought', amountDisplay],
              ].map(([l, v], i) => `
                <tr style="${i % 2 === 0 ? 'background:#fff' : 'background:#f9fafb'}">
                  <td style="padding:6px 10px;color:#555;width:200px;
                      border-bottom:1px solid #eee;font-weight:bold">${l}</td>
                  <td style="padding:6px 10px;border-bottom:1px solid #eee">${v}</td>
                </tr>
              `).join('')}
            </table>

            <p>
              Under Part 19 of the Nigerian Civil Aviation Regulations (NCAR) 2023,
              your airline is liable for the payment of statutory compensation in respect
              of the above flight. The circumstances giving rise to this claim do not
              constitute an extraordinary circumstance exempting your airline from liability.
            </p>

            <p>
              We hereby <strong>formally demand</strong> payment of
              <strong>${amountDisplay}</strong> within
              <strong>14 days</strong> of receipt of this letter, to the following account:
            </p>

            <table cellpadding="6" cellspacing="0"
                   style="border-collapse:collapse;margin:16px 0;font-size:13px;
                          border:1px solid #c8d6e5">
              <tr style="background:#002855">
                <td colspan="2" style="padding:8px 12px;color:#fff;font-weight:bold">
                  PAYMENT DETAILS
                </td>
              </tr>
              ${[
                ['Account Name', 'CLAIMS ASSIST LTD'],
                ['Bank', 'First City Monument Bank (FCMB)'],
                ['Account Number', '2008264829'],
                ['Payment Reference', `CA/${claimId}`],
              ].map(([l, v]) => `
                <tr>
                  <td style="padding:7px 12px;font-weight:bold;color:#555;
                      border-bottom:1px solid #e0e8f0;background:#f2f5f9">${l}</td>
                  <td style="padding:7px 12px;border-bottom:1px solid #e0e8f0;
                      font-weight:bold;color:#002855">${v}</td>
                </tr>
              `).join('')}
            </table>

            <p>
              Please be advised that failure to settle this claim within 14 days will,
              <strong>without further notice</strong>, result in:
            </p>
            <ul style="line-height:1.9">
              <li>A formal complaint to the <strong>Nigerian Civil Aviation Authority (NCAA)</strong>;</li>
              <li>A formal complaint to the <strong>Federal Competition and Consumer Protection Commission (FCCPC)</strong>; and</li>
              <li>The commencement of <strong>proceedings in the Federal High Court of Nigeria</strong> for the full statutory amount, plus interest and legal costs.</li>
            </ul>

            <p style="font-size:12px;color:#777">
              This letter is written without prejudice to all other rights and remedies
              available to our client.
            </p>

            <p>
              Yours faithfully,<br/>
              <strong>Claims Assist Legal Team</strong><br/>
              <a href="mailto:info@claimshub.online" style="color:#002855">info@claimshub.online</a>
            </p>
          </div>
        </div>
      `,
      attachments: [
        {
          filename: `LOA_${safeName}_${claimId}.pdf`,
          content: Buffer.from(loaBytes),
          contentType: 'application/pdf',
        },
        {
          filename: `DemandLetter_${safeName}_${claimId}.pdf`,
          content: Buffer.from(demandBytes),
          contentType: 'application/pdf',
        },
      ],
    });

    return change.after.ref.update({
      trigger_airline_email: false,
      airline_email_status: 'Awaiting reply',
      loa_url: loaUrl,
      demand_letter_url: demandUrl,
    });
  });

// ─── 5. On Trigger Solicitor Email → Generate Final Legal Notice, email airline ─
// Fires when a staff member sets trigger_solicitor_email = true from the
// Solicitors Workspace CRM page. Sends a more serious Final Legal Notice.

exports.onTriggerSolicitorEmail = functions
  .runWith({ secrets: ['HOSTINGER_EMAIL_PASS'], timeoutSeconds: 120 })
  .firestore.document('claims/{claimId}')
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const prevData = change.before.data();

    if (!(newData.trigger_solicitor_email === true && prevData.trigger_solicitor_email !== true)) {
      return null;
    }

    const claimId = context.params.claimId;
    const clientName = newData.full_name || 'Client';
    const safeName = clientName.replace(/\s+/g, '_');
    const today = new Date().toLocaleDateString('en-GB', { day: 'numeric', month: 'long', year: 'numeric' });
    const rawAmount = newData.claims_amount;
    const amountText = rawAmount || 'the applicable statutory amount';
    const amountHtml = rawAmount || 'the applicable statutory amount';

    // ── Build Final Legal Notice PDF ─────────────────────────────────────────
    const pdfDoc = await PDFDocument.create();
    const bold = await pdfDoc.embedFont(StandardFonts.HelveticaBold);
    const reg = await pdfDoc.embedFont(StandardFonts.Helvetica);

    const page = pdfDoc.addPage([595, 842]);
    const navy = rgb(0, 0.157, 0.333);
    const red = rgb(0.7, 0.05, 0.05);
    const grey = rgb(0.4, 0.4, 0.4);
    const ltGrey = rgb(0.8, 0.8, 0.8);
    const black = rgb(0, 0, 0);
    const white = rgb(1, 1, 1);

    // Header band
    page.drawRectangle({ x: 0, y: 792, width: 595, height: 50, color: navy });
    page.drawText('CLAIMS ASSIST LIMITED', { x: 40, y: 818, size: 14, font: bold, color: white });
    page.drawText('Legal Department  |  info@claimshub.online', { x: 40, y: 797, size: 8, font: reg, color: ltGrey });

    let y = 762;
    page.drawText(`Ref: CA/${claimId}/LEGAL-NOTICE`, { x: 40, y, size: 9, font: reg, color: grey });
    y -= 13;
    page.drawText(`Date: ${today}`, { x: 40, y, size: 9, font: reg, color: grey });

    y -= 18;
    page.drawText('To:', { x: 40, y, size: 10.5, font: bold, color: black });
    y -= 14;
    page.drawText('Legal / Customer Relations Department', { x: 40, y, size: 10.5, font: reg, color: black });
    y -= 14;
    page.drawText(newData.airline_name || 'The Airline', { x: 40, y, size: 10.5, font: bold, color: black });
    y -= 14;
    page.drawText('BY EMAIL — FINAL NOTICE BEFORE LEGAL ACTION', { x: 40, y, size: 8.5, font: bold, color: red });

    y -= 18;
    page.drawLine({ start: { x: 40, y }, end: { x: 555, y }, thickness: 2, color: red });
    y -= 14;
    page.drawText('FINAL LEGAL NOTICE — NCAR 2023 PART 19', { x: 40, y, size: 12, font: bold, color: red });
    y -= 4;
    page.drawLine({ start: { x: 40, y }, end: { x: 555, y }, thickness: 2, color: red });

    y -= 18;
    page.drawText('Dear Legal Department,', { x: 40, y, size: 10.5, font: reg, color: black });

    y -= 16;
    for (const line of [
      `We write on behalf of our client, ${clientName} ("the Passenger"), in`,
      'respect of the above-referenced flight compensation claim. Despite our',
      'earlier formal demand letter, to which no satisfactory response has been',
      'received, this matter remains unresolved.',
    ]) {
      page.drawText(line, { x: 40, y, size: 10, font: reg, color: black });
      y -= 13;
    }

    y -= 8;
    page.drawText('PARTICULARS OF CLAIM', { x: 40, y, size: 10.5, font: bold, color: navy });
    y -= 5;
    page.drawLine({ start: { x: 40, y }, end: { x: 555, y }, thickness: 0.5, color: ltGrey });
    y -= 14;

    for (const [label, value] of [
      ['Passenger', clientName],
      ['PNR / Booking Reference', newData.pnr || newData.booking_reference || 'N/A'],
      ['Flight Number', newData.flight_number || 'N/A'],
      ['Date of Travel', newData.flight_date || 'N/A'],
      ['Route', `${newData.departure || 'N/A'} to ${newData.destination || 'N/A'}`],
      ['Duration of Delay', newData.duration_of_delay || 'N/A'],
      ['Compensation Sought', amountText],
    ]) {
      page.drawText(`${label}:`, { x: 40, y, size: 10, font: bold, color: grey });
      page.drawText(String(value), { x: 225, y, size: 10, font: reg, color: black });
      y -= 15;
    }

    y -= 8;
    page.drawText('FINAL DEMAND', { x: 40, y, size: 10.5, font: bold, color: red });
    y -= 5;
    page.drawLine({ start: { x: 40, y }, end: { x: 555, y }, thickness: 0.5, color: rgb(0.8, 0.3, 0.3) });
    y -= 13;

    page.drawText(`This is your FINAL OPPORTUNITY to settle this claim for ${amountText}.`, { x: 40, y, size: 10, font: bold, color: black });
    y -= 13;
    page.drawText('Payment must be received within SEVEN (7) DAYS of this notice:', { x: 40, y, size: 10, font: reg, color: black });
    y -= 15;

    for (const [label, value] of [
      ['Account Name', 'CLAIMS ASSIST LTD'],
      ['Bank', 'First City Monument Bank (FCMB)'],
      ['Account Number', '2008264829'],
      ['Payment Reference', `CA/${claimId}`],
    ]) {
      page.drawText(`${label}:`, { x: 55, y, size: 10, font: bold, color: grey });
      page.drawText(value, { x: 225, y, size: 10, font: bold, color: navy });
      y -= 15;
    }

    y -= 8;
    page.drawText('IMMEDIATE CONSEQUENCES OF CONTINUED NON-COMPLIANCE', { x: 40, y, size: 10.5, font: bold, color: red });
    y -= 5;
    page.drawLine({ start: { x: 40, y }, end: { x: 555, y }, thickness: 0.5, color: rgb(0.8, 0.3, 0.3) });
    y -= 13;

    for (const line of [
      '(a)  An emergency complaint filed with the Nigerian Civil Aviation Authority (NCAA)',
      '      seeking immediate regulatory sanctions;',
      '(b)  A complaint to the Federal Competition and Consumer Protection Commission (FCCPC)',
      '      for consumer rights violations; and',
      '(c)  Commencement of proceedings in the Federal High Court of Nigeria without',
      '      further notice, seeking the full statutory amount, interest at 10% p.a.,',
      '      plus all legal costs assessed against your airline.',
    ]) {
      page.drawText(line, { x: 50, y, size: 10, font: reg, color: black });
      y -= 13;
    }

    y -= 10;
    page.drawText('NO FURTHER NOTICE WILL BE GIVEN.', { x: 40, y, size: 11, font: bold, color: red });
    y -= 18;
    page.drawText('This letter is written without prejudice to all other rights and remedies available to our client.', {
      x: 40, y, size: 9, font: reg, color: grey,
    });

    y -= 22;
    page.drawText('Yours faithfully,', { x: 40, y, size: 10.5, font: reg, color: black });
    y -= 24;
    page.drawText('CLAIMS ASSIST LEGAL TEAM', { x: 40, y, size: 11, font: bold, color: navy });
    y -= 14;
    page.drawText('info@claimshub.online', { x: 40, y, size: 10, font: reg, color: navy });

    const solicitorPdfBytes = await pdfDoc.save();
    const solicitorUrl = await storePdf(claimId, `FinalLegalNotice_${claimId}.pdf`, solicitorPdfBytes);

    const airlineEmail = newData.airline_email_selection || newData.airline_email;

    await createTransporter().sendMail({
      from: '"Claims Assist Legal" <info@claimshub.online>',
      to: airlineEmail,
      subject: `FINAL LEGAL NOTICE: ${clientName} | Flight ${newData.flight_number || 'N/A'} | Ref: CA/${claimId}`,
      html: `
        <div style="font-family:'Times New Roman',serif;line-height:1.8;max-width:700px;color:#111">
          <table width="100%" cellpadding="0" cellspacing="0">
            <tr>
              <td style="background:#7b0c0c;padding:20px 28px">
                <span style="color:#fff;font-size:18px;font-weight:bold;font-family:Arial">CLAIMS ASSIST LIMITED</span><br/>
                <span style="color:#f8c0c0;font-size:11px;font-family:Arial">Legal Department &nbsp;|&nbsp; info@claimshub.online</span>
              </td>
            </tr>
          </table>

          <div style="padding:28px 0">
            <p style="margin:0 0 4px"><strong>Ref:</strong> CA/${claimId}/LEGAL-NOTICE</p>
            <p style="margin:0 0 20px;color:#555;font-size:13px">${today}</p>

            <p style="margin:0 0 4px;color:#7b0c0c;font-size:11px;font-weight:bold">
              BY EMAIL — FINAL NOTICE BEFORE LEGAL ACTION
            </p>

            <hr style="border:none;border-top:3px solid #7b0c0c;margin:12px 0 8px"/>
            <p style="font-size:16px;font-weight:bold;color:#7b0c0c;margin:0 0 8px">
              FINAL LEGAL NOTICE — NCAR 2023 PART 19
            </p>
            <hr style="border:none;border-top:3px solid #7b0c0c;margin:0 0 24px"/>

            <p>Dear Legal Department,</p>

            <p>
              We write on behalf of our client, <strong>${clientName}</strong>, in respect of the
              above-referenced flight compensation claim. Despite our earlier formal demand letter,
              to which no satisfactory response has been received, this matter remains unresolved.
              <strong>This is our final communication before legal action commences.</strong>
            </p>

            <table width="100%" cellpadding="6" cellspacing="0"
                   style="border-collapse:collapse;margin:16px 0;font-size:13px">
              <tr style="background:#fdf0f0">
                <td colspan="2" style="padding:8px 10px;font-weight:bold;color:#7b0c0c;
                    border-bottom:1px solid #f0c0c0">PARTICULARS OF CLAIM</td>
              </tr>
              ${[
                ['Passenger', clientName],
                ['PNR / Booking Reference', newData.pnr || newData.booking_reference || 'N/A'],
                ['Flight Number', newData.flight_number || 'N/A'],
                ['Date of Travel', newData.flight_date || 'N/A'],
                ['Route', `${newData.departure || 'N/A'} &rarr; ${newData.destination || 'N/A'}`],
                ['Duration of Delay', newData.duration_of_delay || 'N/A'],
                ['Compensation Sought', amountHtml],
              ].map(([l, v], i) => `
                <tr style="${i % 2 === 0 ? 'background:#fff' : 'background:#fdf9f9'}">
                  <td style="padding:6px 10px;color:#555;width:200px;
                      border-bottom:1px solid #f5e0e0;font-weight:bold">${l}</td>
                  <td style="padding:6px 10px;border-bottom:1px solid #f5e0e0">${v}</td>
                </tr>
              `).join('')}
            </table>

            <div style="background:#fff5f5;border:2px solid #7b0c0c;border-radius:8px;padding:20px;margin:20px 0">
              <p style="color:#7b0c0c;font-weight:bold;margin:0 0 12px;font-size:15px">
                FINAL DEMAND — PAYMENT DUE WITHIN 7 DAYS
              </p>
              <p style="margin:0 0 12px">
                This is your <strong>FINAL OPPORTUNITY</strong> to settle this claim for
                <strong>${amountHtml}</strong> before court proceedings commence.
              </p>

              <table cellpadding="6" cellspacing="0"
                     style="border-collapse:collapse;font-size:13px;border:1px solid #7b0c0c">
                <tr style="background:#7b0c0c">
                  <td colspan="2" style="padding:8px 12px;color:#fff;font-weight:bold">PAYMENT DETAILS</td>
                </tr>
                ${[
                  ['Account Name', 'CLAIMS ASSIST LTD'],
                  ['Bank', 'First City Monument Bank (FCMB)'],
                  ['Account Number', '2008264829'],
                  ['Payment Reference', `CA/${claimId}`],
                ].map(([l, v]) => `
                  <tr>
                    <td style="padding:7px 12px;font-weight:bold;color:#555;background:#fdf0f0;
                        border-bottom:1px solid #f0c0c0">${l}</td>
                    <td style="padding:7px 12px;border-bottom:1px solid #f0c0c0;
                        font-weight:bold;color:#7b0c0c">${v}</td>
                  </tr>
                `).join('')}
              </table>
            </div>

            <p><strong>Failure to pay within 7 days will, without further notice, result in:</strong></p>
            <ul style="line-height:2;color:#333">
              <li>Emergency complaint to the <strong>Nigerian Civil Aviation Authority (NCAA)</strong> seeking regulatory sanctions;</li>
              <li>Complaint to the <strong>Federal Competition and Consumer Protection Commission (FCCPC)</strong>; and</li>
              <li><strong>Immediate commencement of proceedings</strong> in the Federal High Court of Nigeria for the full statutory amount, interest at 10% per annum, and all legal costs assessed against your airline.</li>
            </ul>

            <p style="font-weight:bold;color:#7b0c0c;font-size:15px">NO FURTHER NOTICE WILL BE GIVEN.</p>

            <p style="font-size:12px;color:#777">
              This letter is written without prejudice to all other rights and remedies available to our client.
            </p>

            <p>
              Yours faithfully,<br/>
              <strong>Claims Assist Legal Team</strong><br/>
              <a href="mailto:info@claimshub.online" style="color:#7b0c0c">info@claimshub.online</a>
            </p>
          </div>
        </div>
      `,
      attachments: [{
        filename: `FinalLegalNotice_${safeName}_${claimId}.pdf`,
        content: Buffer.from(solicitorPdfBytes),
        contentType: 'application/pdf',
      }],
    });

    return change.after.ref.update({
      trigger_solicitor_email: false,
      solicitor_email_status: 'Sent',
      solicitor_letter_url: solicitorUrl,
      solicitor_sent_at: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

// ─── 6. On Claim Status Changed → Notify client by email ─────────────────────

exports.onClaimStatusChanged = functions
  .runWith({ secrets: ['HOSTINGER_EMAIL_PASS'] })
  .firestore.document('claims/{claimId}')
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const prevData = change.before.data();

    if (newData.claim_status === prevData.claim_status) return null;

    const clientEmail = newData.client_email;
    if (!clientEmail) return null;

    const claimId = context.params.claimId;
    const statusPortalUrl =
      `https://claimshub.online/claimStatus` +
      `?claimRef=claims%2F${claimId}&token=${newData.secure_token}`;

    let subject = '';
    let bodyHtml = '';

    switch (newData.claim_status) {
      case 'Under Review':
        subject = 'Your Claim is Now Under Review — Claims Assist';
        bodyHtml = `
          <p>Hi ${newData.full_name || 'Customer'},</p>
          <p>Great news — our team has received your evidence and your claim is now
             <strong>under review</strong>.</p>
          <p>We are preparing your formal demand letter to send to
             <strong>${newData.airline_name || 'the airline'}</strong>. This typically
             takes 1–3 business days.</p>
          <p>You can track your claim progress at any time using the button below.</p>
        `;
        break;

      case 'Awaiting Reply':
        subject = 'We\'ve Contacted the Airline on Your Behalf — Claims Assist';
        bodyHtml = `
          <p>Hi ${newData.full_name || 'Customer'},</p>
          <p>We have sent a <strong>formal demand letter</strong> to
             <strong>${newData.airline_name || 'the airline'}</strong> on your behalf.</p>
          <p>Airlines have <strong>14 days</strong> to respond. We will notify you
             immediately once we hear back. No action is needed from you right now.</p>
        `;
        break;

      case 'Won':
        subject = 'Your Claim Has Been Approved! — Claims Assist';
        bodyHtml = `
          <p>Hi ${newData.full_name || 'Customer'},</p>
          <p>Congratulations! <strong>Your flight compensation claim has been approved.</strong></p>
          <p>Our team will contact you within 3–5 business days to arrange your
             compensation payment after our success fee has been deducted.</p>
          <p>Thank you for trusting Claims Assist.</p>
        `;
        break;

      case 'Lost':
        subject = 'Update on Your Flight Compensation Claim — Claims Assist';
        bodyHtml = `
          <p>Hi ${newData.full_name || 'Customer'},</p>
          <p>We're sorry to inform you that the airline has not agreed to settle your
             claim at this stage.</p>
          <p>Our team will review the airline's response and contact you to discuss
             your options — including escalation to the NCAA or legal proceedings
             at <strong>no upfront cost to you</strong>.</p>
          <p>Please do not be discouraged. Many claims succeed on appeal.</p>
        `;
        break;

      case 'Submit to Solicitor':
        subject = 'Your Claim Has Been Referred to Our Legal Team — Claims Assist';
        bodyHtml = `
          <p>Hi ${newData.full_name || 'Customer'},</p>
          <p>Your claim has been <strong>escalated to our legal team</strong> for further
             action against <strong>${newData.airline_name || 'the airline'}</strong>.</p>
          <p>A solicitor will review your case and may contact you for additional
             information. We will keep you updated throughout the process.</p>
        `;
        break;

      default:
        return null;
    }

    const html = `
      <div style="font-family:Arial,sans-serif;max-width:600px;margin:0 auto;color:#333">
        <div style="background:#002855;padding:20px 28px;border-radius:8px 8px 0 0">
          <h2 style="color:#fff;margin:0;font-size:20px">Claims Assist</h2>
        </div>
        <div style="padding:28px;border:1px solid #e0e0e0;border-top:none;border-radius:0 0 8px 8px">
          ${bodyHtml}
          <p style="margin-top:24px;text-align:center">
            <a href="${statusPortalUrl}"
               style="background:#002855;color:#fff;padding:12px 24px;
                      border-radius:6px;text-decoration:none;font-weight:bold;font-size:14px">
              View My Claim Status
            </a>
          </p>
          <hr style="border:none;border-top:1px solid #e0e0e0;margin:24px 0"/>
          <p style="font-size:12px;color:#999;text-align:center">
            Questions? Email us at
            <a href="mailto:info@claimshub.online" style="color:#002855">info@claimshub.online</a>
          </p>
        </div>
      </div>
    `;

    try {
      await createTransporter().sendMail({
        from: '"Claims Assist" <info@claimshub.online>',
        to: clientEmail,
        subject,
        html,
      });
    } catch (e) {
      console.error('[onClaimStatusChanged]', e.message);
    }

    return null;
  });

// ─── 7. On Lead Write → Aggregate stats/dashboard ────────────────────────────
// Maintains two aggregates in stats/dashboard:
//
//   weekly_lead_counts  — [0..6] ints, index = JS Date.getDay() (0=Sun…6=Sat).
//                         Counts only leads created in the CURRENT calendar week.
//                         Recalculated on every leads write so it's always accurate.
//
//   lead_sources        — all-time { source: count } map, kept via atomic
//                         increments / decrements so no full-collection scan needed.

exports.onLeadWrite = functions.firestore
  .document('leads/{leadId}')
  .onWrite(async (change, context) => {
    const db = admin.firestore();
    const statsRef = db.doc('stats/dashboard');

    // ── Atomic update for lead_sources (all-time) ────────────────────────────
    const sourceUpdates = {};
    const beforeData = change.before.exists ? change.before.data() : null;
    const afterData  = change.after.exists  ? change.after.data()  : null;

    const oldSource = beforeData?.utm_source || null;
    const newSource = afterData?.utm_source  || null;

    if (!beforeData && afterData) {
      // Document created
      if (newSource) sourceUpdates[`lead_sources.${newSource}`] = admin.firestore.FieldValue.increment(1);
    } else if (beforeData && !afterData) {
      // Document deleted
      if (oldSource) sourceUpdates[`lead_sources.${oldSource}`] = admin.firestore.FieldValue.increment(-1);
    } else if (beforeData && afterData && oldSource !== newSource) {
      // Source field changed
      if (oldSource) sourceUpdates[`lead_sources.${oldSource}`] = admin.firestore.FieldValue.increment(-1);
      if (newSource) sourceUpdates[`lead_sources.${newSource}`] = admin.firestore.FieldValue.increment(1);
    }

    if (Object.keys(sourceUpdates).length > 0) {
      await statsRef.set(sourceUpdates, { merge: true });
    }

    // ── Full recalculation for weekly_lead_counts (current week) ─────────────
    const now = new Date();
    const weekStart = new Date(now);
    weekStart.setDate(now.getDate() - now.getDay()); // rewind to Sunday
    weekStart.setHours(0, 0, 0, 0);
    weekStart.setMilliseconds(0);

    const weekEnd = new Date(weekStart);
    weekEnd.setDate(weekStart.getDate() + 7);

    const snapshot = await db
      .collection('leads')
      .where('created_at', '>=', admin.firestore.Timestamp.fromDate(weekStart))
      .where('created_at', '<',  admin.firestore.Timestamp.fromDate(weekEnd))
      .get();

    // 7 slots: index 0 = Sunday … index 6 = Saturday
    const weekly = [0, 0, 0, 0, 0, 0, 0];
    snapshot.forEach((doc) => {
      const ts = doc.data().created_at;
      if (ts && typeof ts.toDate === 'function') {
        weekly[ts.toDate().getDay()]++;
      }
    });

    await statsRef.set({
      weekly_lead_counts: weekly,
      week_start: admin.firestore.Timestamp.fromDate(weekStart),
      last_updated: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    console.log(`[onLeadWrite] Stats updated. Weekly: ${weekly}. Sources: ${JSON.stringify(sourceUpdates)}`);
    return null;
  });

// ─── 8. Send Manual Airline Email (called from Flutter app) ──────────────────

exports.sendManualAirlineEmail = functions
  .runWith({ secrets: ['HOSTINGER_EMAIL_PASS'] })
  .https.onRequest((req, res) => {
    cors(req, res, async () => {
      if (req.method !== 'POST') {
        return res.status(405).json({ error: 'Method not allowed' });
      }

      const {
        airlineEmail, airlineName, clientName, pnr, flightNo,
        route, flightDate, delayDuration, compensation, loaPdfUrl, claimId,
      } = req.body;

      if (!airlineEmail || !clientName || !claimId) {
        return res.status(400).json({
          error: 'airlineEmail, clientName, and claimId are required.',
        });
      }

      const amountDisplay = compensation
        ? `&#x20A6;${Number(compensation).toLocaleString('en-NG')}`
        : 'the applicable statutory amount';

      const mailOptions = {
        from: '"Claims Assist Legal" <info@claimshub.online>',
        to: airlineEmail,
        subject: `FORMAL DEMAND: ${clientName} | PNR: ${pnr || 'N/A'} | Ref: CA/${claimId}`,
        html: `
          <div style="font-family:'Times New Roman',serif;line-height:1.8;max-width:700px;color:#111">
            <table width="100%" cellpadding="0" cellspacing="0">
              <tr>
                <td style="background:#002855;padding:20px 28px">
                  <span style="color:#fff;font-size:18px;font-weight:bold;font-family:Arial">CLAIMS ASSIST LIMITED</span><br/>
                  <span style="color:#aac4e0;font-size:11px;font-family:Arial">Legal Department &nbsp;|&nbsp; info@claimshub.online</span>
                </td>
              </tr>
            </table>

            <div style="padding:28px 0">
              <p style="margin:0 0 4px"><strong>Ref:</strong> CA/${claimId}</p>
              <p style="margin:0 0 20px;color:#555;font-size:13px">${new Date().toLocaleDateString('en-GB', { day: 'numeric', month: 'long', year: 'numeric' })}</p>

              <p style="margin:0 0 4px"><strong>To:</strong></p>
              <p style="margin:0 0 4px">Legal / Customer Relations Department</p>
              <p style="margin:0 0 20px;font-weight:bold">${airlineName || 'The Airline'}</p>

              <hr style="border:none;border-top:2px solid #002855;margin:0 0 8px"/>
              <p style="font-size:15px;font-weight:bold;color:#002855;margin:0 0 8px">
                FORMAL DEMAND FOR STATUTORY COMPENSATION — NCAR 2023 PART 19
              </p>
              <hr style="border:none;border-top:2px solid #002855;margin:0 0 24px"/>

              <p>Dear Legal Department,</p>
              <p>
                We act on behalf of our client, <strong>${clientName}</strong>,
                in relation to flight <strong>${flightNo || 'N/A'}</strong>
                (${route || 'N/A'}) on <strong>${flightDate || 'N/A'}</strong>.
                The flight experienced a delay of <strong>${delayDuration || 'N/A'}</strong>.
              </p>
              <p>
                Under Part 19 of the Nigerian Civil Aviation Regulations (NCAR) 2023,
                your airline is liable for statutory compensation of
                <strong>${amountDisplay}</strong>.
              </p>
              <p>
                We hereby formally demand payment within <strong>14 days</strong>
                of receipt of this letter, to the following account:
              </p>

              <table cellpadding="6" cellspacing="0"
                     style="border-collapse:collapse;margin:16px 0;font-size:13px;
                            border:1px solid #c8d6e5">
                <tr style="background:#002855">
                  <td colspan="2" style="padding:8px 12px;color:#fff;font-weight:bold">
                    PAYMENT DETAILS
                  </td>
                </tr>
                <tr>
                  <td style="padding:7px 12px;font-weight:bold;color:#555;background:#f2f5f9;
                      border-bottom:1px solid #e0e8f0">Account Name</td>
                  <td style="padding:7px 12px;border-bottom:1px solid #e0e8f0;
                      font-weight:bold;color:#002855">CLAIMS ASSIST LTD</td>
                </tr>
                <tr>
                  <td style="padding:7px 12px;font-weight:bold;color:#555;background:#f2f5f9;
                      border-bottom:1px solid #e0e8f0">Bank</td>
                  <td style="padding:7px 12px;border-bottom:1px solid #e0e8f0;
                      font-weight:bold;color:#002855">First City Monument Bank (FCMB)</td>
                </tr>
                <tr>
                  <td style="padding:7px 12px;font-weight:bold;color:#555;background:#f2f5f9;
                      border-bottom:1px solid #e0e8f0">Account Number</td>
                  <td style="padding:7px 12px;border-bottom:1px solid #e0e8f0;
                      font-weight:bold;color:#002855">2008264829</td>
                </tr>
                <tr>
                  <td style="padding:7px 12px;font-weight:bold;color:#555;background:#f2f5f9">
                    Payment Reference</td>
                  <td style="padding:7px 12px;font-weight:bold;color:#002855">CA/${claimId}</td>
                </tr>
              </table>

              ${loaPdfUrl ? `<p>Letter of Authority: <a href="${loaPdfUrl}" style="color:#002855">Download PDF</a></p>` : ''}

              <p>
                Failure to settle within 14 days will result in a formal complaint to the
                NCAA, FCCPC, and commencement of proceedings in the Federal High Court
                without further notice.
              </p>

              <p>
                Yours faithfully,<br/>
                <strong>Claims Assist Legal Team</strong><br/>
                <a href="mailto:info@claimshub.online" style="color:#002855">info@claimshub.online</a>
              </p>
            </div>
          </div>
        `,
      };

      try {
        await createTransporter().sendMail(mailOptions);
        await admin.firestore().doc(`claims/${claimId}`).update({
          airline_email_status: 'Sent',
        }).catch(() => {});
        return res.status(200).json({ success: true });
      } catch (e) {
        console.error('[sendManualAirlineEmail]', e.message);
        return res.status(500).json({ error: e.message });
      }
    });
  });
