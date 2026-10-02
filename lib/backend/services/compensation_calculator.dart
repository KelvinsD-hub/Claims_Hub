import 'package:intl/intl.dart';

/// A stored claim amount as shown to staff.
///
/// Amounts written by the calculator carry their own currency ("₦21,250").
/// Older ones were typed in as bare numbers; those are naira.
String displayClaimAmount(String stored, {String empty = '—'}) {
  final value = stored.trim();
  if (value.isEmpty) return empty;
  return RegExp(r'^\d').hasMatch(value) ? '₦$value' : value;
}

/// What went wrong with the flight.
enum Disruption { delay, cancellation, deniedBoarding, downgrade }

/// Whether the flight is domestic (within Nigeria) or international.
enum FlightType { domestic, international }

/// How firmly Part 19 supports a claim on the facts given.
///
/// [maybe] is not a soft "yes": it means the regulation leaves room for the
/// airline to dispute the claim, so staff should review before promising
/// anything to the passenger.
enum Outcome { yes, maybe, no }

/// The result returned by [CompensationCalculator.calculate].
class EligibilityResult {
  const EligibilityResult({
    required this.outcome,
    required this.amount,
    required this.estimateValue,
    required this.headline,
    required this.points,
    required this.flightType,
  });

  final Outcome outcome;

  /// Display amount: a naira figure when the fare is known ("₦12,500"),
  /// otherwise the rate ("25% of your ticket price"). "—" when nothing is due.
  final String amount;

  /// The same value in the form stored on a lead's `estimate_value`.
  final String estimateValue;

  final String headline;
  final List<String> points;
  final FlightType flightType;

  /// True when there is a claim worth starting (certain or needing review).
  bool get eligible => outcome != Outcome.no;
}

/// Assesses a disrupted flight under the Nigeria Civil Aviation Regulations
/// 2023, Part 19 (Amendment 4).
///
/// Mirrors the NCAR branch of the website's rules engine
/// (claims-assist-site/web/src/lib/engine.ts) — the two must give the same
/// answer for the same facts, so change them together. Section numbers are
/// cited so each branch can be checked against the text.
///
/// Compensation is a share of the ticket price — 25% domestic, 30%
/// international (19.8.1.1) — and is only one of three separate remedies:
/// care, refund or re-routing, and compensation each have their own trigger.
class CompensationCalculator {
  CompensationCalculator._();

  static const String _ncaaEscalation =
      'The claim goes to the airline first. If it stays unresolved, Part 19 '
      'allows a complaint to the NCAA\'s consumer protection directorate — '
      'which we can file for you with your written authority.';

  static const Map<Disruption, String> disruptionLabels = {
    Disruption.delay: 'Flight delayed',
    Disruption.cancellation: 'Flight cancelled',
    Disruption.deniedBoarding: 'Denied boarding',
    Disruption.downgrade: 'Downgraded to a lower class',
  };

  /// The Part 19 minimum as a percentage of the ticket price.
  ///
  /// 19.8.1.1: 25% domestic, 30% international for delay, cancellation and
  /// denied boarding. 19.11: 30% domestic, 50% international for a downgrade,
  /// payable on top of the fare difference.
  static int ratePercent(FlightType flightType, {bool downgrade = false}) {
    final domestic = flightType == FlightType.domestic;
    if (downgrade) return domestic ? 30 : 50;
    return domestic ? 25 : 30;
  }

  static String _naira(double value) {
    final rounded = (value * 100).round() / 100;
    return '₦${NumberFormat('#,##0.##').format(rounded)}';
  }

  /// A Part 19 percentage as a display amount.
  ///
  /// With the fare we can state a figure; without it we state the rate and
  /// nothing more. Never a guessed fare — an invented number here becomes the
  /// number the passenger expects to be paid.
  static ({String amount, String estimateValue, String basis}) _shareOfFare(
      int pct, double? fare) {
    if (fare != null && fare > 0) {
      final sum = _naira(fare * pct / 100);
      return (
        amount: sum,
        estimateValue: '$sum ($pct% of ${_naira(fare)} fare)',
        basis: '$pct% of the ${_naira(fare)} you paid comes to $sum.',
      );
    }
    return (
      amount: '$pct% of your ticket price',
      estimateValue: '$pct% of ticket price',
      basis: 'Tell us what the ticket cost and we can put a figure on it — '
          '$pct% of the price you paid.',
    );
  }

  /// Returns an [EligibilityResult] for the given facts.
  ///
  /// [delayHours] — how late the flight was; required for a delay.
  /// [enoughNotice] — cancellations only: whether the passenger was told at
  ///   least 24 hours (domestic) or seven days (international) before
  ///   departure. Null when they are not sure.
  /// [isExtraordinaryCircumstance] — true if the airline blamed weather, air
  ///   traffic control, security or another cause outside its control.
  /// [fare] — the ticket price in naira, when the passenger has it to hand.
  static EligibilityResult calculate({
    required Disruption disruption,
    required FlightType flightType,
    double? delayHours,
    bool? enoughNotice,
    bool isExtraordinaryCircumstance = false,
    double? fare,
  }) {
    final domestic = flightType == FlightType.domestic;
    final pct = ratePercent(flightType);
    final share = _shareOfFare(pct, fare);
    final scope = domestic ? 'flights within Nigeria' : 'international flights';
    final rate = 'Part 19.8.1.1 sets compensation at a minimum of $pct% of '
        'the ticket price for $scope.';
    final badReason = isExtraordinaryCircumstance;
    final exReason = badReason
        ? 'The airline blamed an extraordinary circumstance. If it can prove '
            'the disruption could not have been avoided, no compensation is '
            'due — we review the stated reason against the available evidence.'
        : 'The cause you described sounds within the airline\'s control. The '
            'airline can still avoid compensation if it proves extraordinary '
            'circumstances, so this is an assessment, not a guarantee.';

    EligibilityResult result({
      required Outcome outcome,
      required String amount,
      required String estimateValue,
      required String headline,
      required List<String> points,
    }) =>
        EligibilityResult(
          outcome: outcome,
          amount: amount,
          estimateValue: estimateValue,
          headline: headline,
          points: points,
          flightType: flightType,
        );

    switch (disruption) {
      // 19.11: the fare difference back, plus 30% (domestic) or 50%
      // (international) of the ticket price.
      case Disruption.downgrade:
        final dPct = ratePercent(flightType, downgrade: true);
        final d = _shareOfFare(dPct, fare);
        return result(
          outcome: Outcome.yes,
          amount: 'Fare difference + ${d.amount}',
          estimateValue: 'Fare difference + ${d.estimateValue}',
          headline: 'A downgrade entitles you to the fare difference plus '
              '$dPct% of the ticket price.',
          points: [
            'Part 19.11 requires the airline to refund the difference between '
                'the class you paid for and the class you flew, plus $dPct% of '
                'the ticket price on $scope.',
            d.basis,
            'Keep your original booking confirmation and your boarding pass — '
                'together they show the class you bought and the class you '
                'were given.',
            _ncaaEscalation,
          ],
        );

      case Disruption.delay:
        final h = delayHours;
        if (h == null || h < 2) {
          return result(
            outcome: Outcome.no,
            amount: '—',
            estimateValue: 'Not eligible',
            headline:
                'Part 19 does not provide anything for a delay under two hours.',
            points: [
              'The airline must tell you the reason for a delay within 30 '
                  'minutes of the scheduled departure time.',
              'Refreshments and the means to make calls or send messages are '
                  'due once a delay reaches two hours.',
            ],
          );
        }

        if (domestic) {
          // 19.6.1.1(d): compensation only where departure is more than six
          // hours late.
          if (h > 6) {
            final certain = !badReason;
            return result(
              outcome: certain ? Outcome.yes : Outcome.maybe,
              amount: share.amount,
              estimateValue: share.estimateValue,
              headline: certain
                  ? 'A delay of more than six hours entitles you to '
                      'compensation of at least $pct% of your fare.'
                  : 'You may be entitled to compensation of at least $pct% of '
                      'your fare.',
              points: [
                'On a domestic flight, Part 19.6.1.1(d) gives compensation '
                    'where departure is more than six hours later than '
                    'announced.',
                '$rate ${share.basis}',
                'Separately, once the delay passed three hours you were '
                    'entitled to choose a full refund or re-routing instead '
                    'of waiting.',
                exReason,
                _ncaaEscalation,
              ],
            );
          }
          if (h < 3) {
            return result(
              outcome: Outcome.no,
              amount: '—',
              estimateValue: 'Care only — no compensation',
              headline: 'A domestic delay of two to three hours carries a '
                  'right to care, not compensation.',
              points: [
                'From two hours the airline owes refreshments — water, soft '
                    'drinks, snacks — and two calls, texts or emails, free of '
                    'charge.',
                'The right to a refund or re-routing starts beyond three '
                    'hours, and compensation only where departure is more '
                    'than six hours late.',
                'If you paid for refreshments because the airline offered '
                    'none, keep the receipts and ask the airline to reimburse '
                    'you.',
              ],
            );
          }
          return result(
            outcome: Outcome.no,
            amount: '—',
            estimateValue: 'Refund or re-routing — no compensation',
            headline: 'A domestic delay of three to six hours gives you a '
                'refund or re-routing, not compensation.',
            points: [
              'Beyond three hours, Part 19.6.1.1(b) lets you choose a full '
                  'refund of the unused ticket or re-routing to your '
                  'destination.',
              'A refund paid in cash is due immediately on a domestic flight; '
                  'by bank transfer, within 14 days.',
              'Compensation of 25% of the fare applies only where departure '
                  'is more than six hours late.',
              'If you asked for a refund and the airline refused or has not '
                  'paid, send us your details and we will review it.',
            ],
          );
        }

        // International. 19.6.2.1(a) attaches compensation to a delay of
        // "between two and four hours"; beyond four hours the text lists meals
        // and accommodation and does not repeat it. We state that plainly
        // rather than read the longer delay as certainly covered.
        final withinBand = h <= 4;
        final sure = withinBand && !badReason;
        return result(
          outcome: sure ? Outcome.yes : Outcome.maybe,
          amount: share.amount,
          estimateValue: share.estimateValue,
          headline: sure
              ? 'Part 19 provides compensation of at least $pct% of your '
                  'ticket price for this delay.'
              : 'You may be entitled to compensation of at least $pct% of '
                  'your ticket price.',
          points: [
            withinBand
                ? 'On an international flight, Part 19.6.2.1(a) provides '
                    'compensation for a delay of between two and four hours.'
                : 'Part 19.6.2.1(a) provides compensation for an '
                    'international delay of between two and four hours. For a '
                    'longer delay the regulation lists meals and hotel '
                    'accommodation and does not restate the compensation, so '
                    'the airline may dispute it — which is why this is a '
                    'review, not a promise.',
            '$rate ${share.basis}',
            'Beyond four hours the airline also owes you a meal, and hotel '
                'accommodation with transport where departure is six or more '
                'hours late.',
            exReason,
            _ncaaEscalation,
          ],
        );

      case Disruption.cancellation:
        // 19.7.1.1(c) domestic: no compensation with 24 hours' notice.
        // 19.7.1.1(d) international: none with seven days' notice.
        if (enoughNotice == true) {
          return result(
            outcome: Outcome.no,
            amount: '—',
            estimateValue: 'Refund or re-routing — no compensation',
            headline: domestic
                ? 'A cancellation announced at least 24 hours ahead does not '
                    'carry compensation.'
                : 'A cancellation announced at least seven days ahead does '
                    'not carry compensation.',
            points: [
              'You are still entitled to choose between a full refund of the '
                  'unused ticket and re-routing to your destination.',
              'A refund by bank transfer is due within 14 days.',
              'If the airline has refused or not paid your refund, send us '
                  'your details and we will review it.',
            ],
          );
        }
        final unsure = badReason || enoughNotice == null;
        return result(
          outcome: unsure ? Outcome.maybe : Outcome.yes,
          amount: share.amount,
          estimateValue: share.estimateValue,
          headline: unsure
              ? 'You may be entitled to compensation of at least $pct% of '
                  'your ticket price.'
              : 'A late-notice cancellation entitles you to compensation of '
                  'at least $pct% of your ticket price.',
          points: [
            domestic
                ? 'On a domestic flight, Part 19.7.1.1(c) gives compensation '
                    'unless you were told at least 24 hours before departure.'
                : 'On an international flight, Part 19.7.1.1(d) gives '
                    'compensation unless you were told at least seven days '
                    'before departure, or were re-routed to arrive close to '
                    'your original schedule.',
            '$rate ${share.basis}',
            'This is on top of your right to a full refund or re-routing. If '
                'you were re-routed and arrived within '
                '${domestic ? 'one hour' : 'three hours'} of your original '
                'arrival time, the airline may halve the compensation.',
            exReason,
            _ncaaEscalation,
          ],
        );

      // 19.5.1.4: compensation under 19.8 immediately, with refund or
      // re-routing and care alongside.
      case Disruption.deniedBoarding:
        return result(
          outcome: Outcome.yes,
          amount: share.amount,
          estimateValue: share.estimateValue,
          headline: 'Being denied boarding entitles you to compensation of '
              'at least $pct% of your ticket price.',
          points: [
            'Part 19.5.1.4 requires the airline to compensate passengers it '
                'denies boarding to immediately, and to offer a refund or '
                're-routing as well.',
            '$rate ${share.basis}',
            'This applies where you had a confirmed reservation and checked '
                'in on time. If you gave up your seat voluntarily, what you '
                'are owed is whatever you agreed with the airline.',
            _ncaaEscalation,
          ],
        );
    }
  }
}
