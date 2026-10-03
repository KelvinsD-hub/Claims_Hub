import '/components/work_ui.dart';
import '/components/brand_colors.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'supports_model.dart';
export 'supports_model.dart';

const Color _kNavy = Color(0xFF002855);

// ---------------------------------------------------------------------------
// Support contact details. Update these to the real support channels.
// ---------------------------------------------------------------------------
const String _supportEmail = 'info@claimshub.online';
const String _supportPhone = '+233000000000'; // TODO: real support line
const String _supportWhatsApp = '233000000000'; // wa.me number, digits only

// A phone/WhatsApp value still holding a placeholder (all zeros) is not shown,
// so users never dial a junk number. Set real values above to reveal the button.
bool _isRealNumber(String value) {
  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
  return digits.isNotEmpty && digits.replaceAll('0', '').isNotEmpty;
}

class SupportsWidget extends StatefulWidget {
  const SupportsWidget({super.key});

  static String routeName = 'Supports';
  static String routePath = '/supports';

  @override
  State<SupportsWidget> createState() => _SupportsWidgetState();
}

class _SupportsWidgetState extends State<SupportsWidget> {
  late SupportsModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  // Each answer points to the part of the staff manual that covers it.
  static const List<_Faq> _faqs = [
    _Faq(
      question: 'Where do new leads come from?',
      answer:
          'From the website. When a client submits their flight, a lead appears at the top of Leads as "New lead", with no owner. Click Take to make it yours, then contact the client within a day.',
      section: 'intake',
    ),
    _Faq(
      question: 'How does a lead become a claim?',
      answer:
          'Contact the client, move the lead to Contacted, then to Qualified. Qualifying opens the claim for you, and the client is emailed a link to send their evidence. To turn a lead down, move it to Rejected and give a reason.',
      section: 'lead',
    ),
    _Faq(
      question: 'The client has not sent their evidence. What do I do?',
      answer:
          'Chase them by phone or email and record it with Add note. The claim moves on by itself once they send their evidence and sign the terms. If they no longer want to go ahead, move the claim to Withdrawn with a reason.',
      section: 'client',
    ),
    _Faq(
      question: 'Where do I find a client\'s documents?',
      answer:
          'In the Documents part of the claim file, or in the Evidence Locker in the sidebar.',
      section: 'review',
    ),
    _Faq(
      question: 'How is the demand letter sent to the airline?',
      answer:
          'A manager sends it from the Demand letters page, or with Send demand letter in the claim file. The claim must have the client\'s name, airline, flight number, date, route and signature. The claim then moves to Awaiting Reply by itself.',
      section: 'demand',
    ),
    _Faq(
      question: 'Why does a claim say "Held until"?',
      answer:
          'The client did not ask us to start straight away, so nothing may go to the airline until their 14-day cancellation period ends. The letter can be sent after that date.',
      section: 'demand',
    ),
    _Faq(
      question: 'The airline has replied. What now?',
      answer:
          'Use Record airline reply, and Record offer if they offered money. If they pay, move the claim to Won. If they refuse or do not reply in 14 days, move it to With Solicitor.',
      section: 'reply',
    ),
    _Faq(
      question: 'What does the legal team do?',
      answer:
          'Claims at With Solicitor are in the Legal Workspace. A lawyer reviews the file, sends the final notice (7 days to pay), and if needed files an NCAA complaint. Court is decided claim by claim.',
      section: 'legal',
    ),
    _Faq(
      question: 'How do new staff get an account?',
      answer:
          'By invitation only. An admin clicks Invite staff on the Staff page and sends the link by email or WhatsApp. The link works once, for 7 days. The new person opens it and continues with Google or chooses a password.',
      section: 'start',
    ),
    _Faq(
      question: 'I forgot my password.',
      answer:
          'On the sign-in page, click Forgot password? and enter your email. We send you a link to choose a new one. If you joined with Google, use Continue with Google instead.',
      section: 'start',
    ),
    _Faq(
      question: 'Why can\'t I see a page, or a button?',
      answer:
          'Each role only sees the pages and actions its job needs. For example, only managers send demand letters. Ask an admin if you need access.',
      section: 'roles',
    ),
    _Faq(
      question: 'A client does not want AI used on their claim.',
      answer:
          'Open the AI assistant tab in their lead or claim and click "The client does not want AI used". Only a manager can turn it back on.',
      section: 'ai',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SupportsModel());
    _model.searchController ??= TextEditingController();
    _model.searchFocusNode ??= FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _open(String url) => launchURL(url);

  /// The staff manual, served beside the app; [section] jumps to one part.
  Future<void> _openManual([String section = '']) => launchURL(Uri.base
      .resolve('/manual/${section.isEmpty ? '' : '#$section'}')
      .toString());

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    final query = _model.searchController?.text.toLowerCase() ?? '';
    final faqs = query.isEmpty
        ? _faqs
        : _faqs
            .where((f) =>
                f.question.toLowerCase().contains(query) ||
                f.answer.toLowerCase().contains(query))
            .toList();

    return Title(
      title: 'Support',
      color: FlutterFlowTheme.of(context).primary.withAlpha(0XFF),
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Scaffold(
          key: scaffoldKey,
          backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
          body: SafeArea(
            top: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const WorkSidebar(selected: WorkPage.support),
                Expanded(
                  child: WorkBody(
                    page: WorkPage.support,
                    title: 'Support',
                    subtitle: 'Help with using Claims Hub',
                    icon: Icons.support_agent,
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // -- Staff manual -----------------------------
                            _ManualCard(onOpen: () => _openManual()),
                            const SizedBox(height: 16),

                            // -- Contact card -----------------------------
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [_kNavy, Color(0xFF013a78)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Get in touch',
                                      style: GoogleFonts.interTight(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white)),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Reach the Claims Assist team — we usually reply within a few hours.',
                                    style: GoogleFonts.inter(
                                        fontSize: 13, color: Colors.white70),
                                  ),
                                  const SizedBox(height: 18),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: [
                                      _ContactButton(
                                        icon: Icons.email_outlined,
                                        label: 'Email us',
                                        onTap: () => _open(
                                            'mailto:$_supportEmail?subject=Claims%20Hub%20Support'),
                                      ),
                                      if (_isRealNumber(_supportWhatsApp))
                                        _ContactButton(
                                          icon: FontAwesomeIcons.whatsapp,
                                          label: 'WhatsApp',
                                          onTap: () => _open(
                                              'https://wa.me/$_supportWhatsApp'),
                                          faIcon: true,
                                        ),
                                      if (_isRealNumber(_supportPhone))
                                        _ContactButton(
                                          icon: Icons.call_outlined,
                                          label: 'Call',
                                          onTap: () =>
                                              _open('tel:$_supportPhone'),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      const Icon(Icons.email_outlined,
                                          size: 15, color: Colors.white70),
                                      const SizedBox(width: 6),
                                      SelectableText(_supportEmail,
                                          style: GoogleFonts.inter(
                                              fontSize: 13,
                                              color: Colors.white)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),

                            // -- FAQ header + search ----------------------
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Frequently asked questions',
                                    style: GoogleFonts.interTight(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: brandBlue(context))),
                                SizedBox(
                                  width: 240,
                                  height: 40,
                                  child: TextField(
                                    controller: _model.searchController,
                                    focusNode: _model.searchFocusNode,
                                    onChanged: (_) => safeSetState(() {}),
                                    decoration: InputDecoration(
                                      hintText: 'Search help...',
                                      hintStyle: const TextStyle(
                                          fontSize: 13, color: Colors.grey),
                                      prefixIcon: const Icon(Icons.search,
                                          size: 18, color: Colors.grey),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                            color: FlutterFlowTheme.of(context)
                                                .alternate),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                            color: FlutterFlowTheme.of(context)
                                                .alternate),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // -- FAQ list ---------------------------------
                            if (faqs.isEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 32),
                                child: Center(
                                  child: Text(
                                    'No help articles match "$query".',
                                    style: GoogleFonts.inter(
                                        fontSize: 14, color: Colors.grey),
                                  ),
                                ),
                              )
                            else
                              Container(
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryBackground,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: FlutterFlowTheme.of(context)
                                          .alternate),
                                ),
                                child: Theme(
                                  data: Theme.of(context).copyWith(
                                      dividerColor: FlutterFlowTheme.of(context)
                                          .alternate),
                                  child: Column(
                                    children: [
                                      for (var i = 0; i < faqs.length; i++)
                                        _FaqTile(
                                          faq: faqs[i],
                                          isLast: i == faqs.length - 1,
                                          onRead: () =>
                                              _openManual(faqs[i].section),
                                        ),
                                    ],
                                  ),
                                ),
                              ),

                            const SizedBox(height: 28),
                            Center(
                              child: Text(
                                'Claims Assist  -  v1.0.0',
                                style: GoogleFonts.inter(
                                    fontSize: 12, color: Colors.grey.shade400),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -- FAQ model ----------------------------------------------------------------

class _Faq {
  const _Faq(
      {required this.question, required this.answer, required this.section});
  final String question;
  final String answer;

  /// The part of the staff manual that covers this.
  final String section;
}

class _FaqTile extends StatelessWidget {
  const _FaqTile(
      {required this.faq, required this.isLast, required this.onRead});
  final _Faq faq;
  final bool isLast;
  final VoidCallback onRead;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom:
                    BorderSide(color: FlutterFlowTheme.of(context).alternate)),
      ),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
        iconColor: brandBlue(context),
        collapsedIconColor: Colors.grey,
        title: Text(
          faq.question,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              faq.answer,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 1.5,
                  color: FlutterFlowTheme.of(context).secondaryText),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onRead,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                foregroundColor: brandBlue(context),
              ),
              icon: const Icon(Icons.menu_book_outlined, size: 16),
              label: Text('Read this in the manual',
                  style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// -- Staff manual card --------------------------------------------------------

class _ManualCard extends StatelessWidget {
  const _ManualCard({required this.onOpen});
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.alternate),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: brandBlue(context).withAlpha(28),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.menu_book_outlined,
                color: brandBlue(context), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Staff manual',
                    style: GoogleFonts.interTight(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.primaryText)),
                const SizedBox(height: 4),
                Text(
                  'How a claim moves through Claims Hub, from the website '
                  'enquiry to paying the client: what to do at each stage, '
                  'the deadlines, and who may do it. New to the team? Start here.',
                  style: GoogleFonts.inter(
                      fontSize: 13, height: 1.45, color: theme.secondaryText),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          FilledButton.icon(
            onPressed: onOpen,
            style: FilledButton.styleFrom(
              backgroundColor: brandBlue(context),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: Text('Open the manual',
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// -- Contact button -----------------------------------------------------------

class _ContactButton extends StatelessWidget {
  const _ContactButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.faIcon = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool faIcon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            faIcon
                ? FaIcon(icon, size: 16, color: brandBlue(context))
                : Icon(icon, size: 18, color: brandBlue(context)),
            const SizedBox(width: 8),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: brandBlue(context))),
          ],
        ),
      ),
    );
  }
}
