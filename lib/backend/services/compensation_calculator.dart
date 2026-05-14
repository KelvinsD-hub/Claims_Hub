import 'package:intl/intl.dart';

/// How long the flight was delayed (or cancelled).
enum DelayCategory {
  underTwo,    // < 2 hours  — not compensable
  twoToThree,  // 2–3 hours
  threeToFive, // 3–5 hours
  fiveOrMore,  // 5+ hours
  cancelled,   // flight cancelled
}

/// Whether the flight is domestic (within Nigeria) or international.
enum FlightType { domestic, international }

/// The result returned by [CompensationCalculator.calculate].
class EligibilityResult {
  const EligibilityResult({
    required this.eligible,
    required this.compensationNGN,
    required this.reason,
    required this.delayLabel,
    required this.flightType,
  });

  final bool eligible;
  final int compensationNGN; // 0 when not eligible
  final String reason;
  final String delayLabel;
  final FlightType flightType;

  /// Naira-formatted compensation amount, e.g. "₦50,000".
  String get formattedAmount =>
      '₦${NumberFormat('#,###').format(compensationNGN)}';
}

/// Calculates flight-delay compensation eligibility under NCAR 2023 Part 19.
///
/// Amounts are estimates based on the published regulation.
/// Actual awards may vary depending on case specifics.
class CompensationCalculator {
  CompensationCalculator._();

  // ── Compensation table (NGN) ────────────────────────────────────────────────
  // Source: Nigerian Civil Aviation Regulations (NCAR) 2023, Part 19.
  static const Map<FlightType, Map<DelayCategory, int>> _table = {
    FlightType.domestic: {
      DelayCategory.twoToThree: 15000,
      DelayCategory.threeToFive: 25000,
      DelayCategory.fiveOrMore: 50000,
      DelayCategory.cancelled: 50000,
    },
    FlightType.international: {
      DelayCategory.twoToThree: 75000,
      DelayCategory.threeToFive: 150000,
      DelayCategory.fiveOrMore: 250000,
      DelayCategory.cancelled: 250000,
    },
  };

  static const Map<DelayCategory, String> _delayLabels = {
    DelayCategory.underTwo: 'Less than 2 hours',
    DelayCategory.twoToThree: '2 to 3 hours',
    DelayCategory.threeToFive: '3 to 5 hours',
    DelayCategory.fiveOrMore: 'More than 5 hours',
    DelayCategory.cancelled: 'Flight cancelled',
  };

  /// Returns an [EligibilityResult] for the given inputs.
  ///
  /// [delay] — how long the flight was delayed or whether it was cancelled.
  /// [flightType] — domestic (within Nigeria) or international.
  /// [isExtraordinaryCircumstance] — true if the cause was weather, ATC,
  ///   security, or another factor outside the airline's control.
  static EligibilityResult calculate({
    required DelayCategory delay,
    required FlightType flightType,
    required bool isExtraordinaryCircumstance,
  }) {
    final label = _delayLabels[delay] ?? '';

    if (delay == DelayCategory.underTwo) {
      return EligibilityResult(
        eligible: false,
        compensationNGN: 0,
        reason: 'Delays under 2 hours do not qualify for compensation '
            'under NCAR 2023 Part 19.',
        delayLabel: label,
        flightType: flightType,
      );
    }

    if (isExtraordinaryCircumstance) {
      return EligibilityResult(
        eligible: false,
        compensationNGN: 0,
        reason: 'Extraordinary circumstances — severe weather, air traffic '
            'control action, or security threats — exempt the airline '
            'from statutory compensation under NCAR 2023 Part 19.',
        delayLabel: label,
        flightType: flightType,
      );
    }

    final amount = _table[flightType]![delay]!;
    final typeLabel =
        flightType == FlightType.domestic ? 'domestic' : 'international';

    return EligibilityResult(
      eligible: true,
      compensationNGN: amount,
      reason: 'Based on your $typeLabel flight and a delay of $label, '
          'you may be entitled to compensation under NCAR 2023 Part 19. '
          'Start your claim — we work on a no-win, no-fee basis.',
      delayLabel: label,
      flightType: flightType,
    );
  }

  /// Human-readable labels for all delay categories (used to populate dropdowns).
  static List<String> get delayLabels =>
      DelayCategory.values.map((d) => _delayLabels[d]!).toList();

  /// Maps a label string back to a [DelayCategory].
  static DelayCategory delayCategoryFromLabel(String label) {
    return _delayLabels.entries
        .firstWhere((e) => e.value == label,
            orElse: () => const MapEntry(DelayCategory.underTwo, ''))
        .key;
  }
}
