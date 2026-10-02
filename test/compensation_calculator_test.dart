// Part 19 rules. Each case mirrors one in the website's engine.test.ts, so the
// CRM checker and the public checker give the same answer for the same facts.

import 'package:flutter_test/flutter_test.dart';

import 'package:claims_hub/backend/services/compensation_calculator.dart';

EligibilityResult check({
  Disruption disruption = Disruption.delay,
  FlightType type = FlightType.domestic,
  double? hours,
  bool? notice,
  bool extraordinary = false,
  double? fare,
}) =>
    CompensationCalculator.calculate(
      disruption: disruption,
      flightType: type,
      delayHours: hours,
      enoughNotice: notice,
      isExtraordinaryCircumstance: extraordinary,
      fare: fare,
    );

void main() {
  group('domestic delay', () {
    test('under two hours: nothing', () {
      expect(check(hours: 1.5).outcome, Outcome.no);
    });
    test('two to three hours: care only', () {
      final r = check(hours: 2.5);
      expect(r.outcome, Outcome.no);
      expect(r.estimateValue, 'Care only — no compensation');
    });
    test('three to six hours: refund or re-routing, no compensation', () {
      for (final h in [3.0, 5.0, 6.0]) {
        final r = check(hours: h);
        expect(r.outcome, Outcome.no, reason: '$h hours');
        expect(r.estimateValue, 'Refund or re-routing — no compensation');
      }
    });
    test('more than six hours: 25% of the fare', () {
      final r = check(hours: 6.5, fare: 80000);
      expect(r.outcome, Outcome.yes);
      expect(r.amount, '₦20,000');
      expect(r.estimateValue, '₦20,000 (25% of ₦80,000 fare)');
    });
    test('more than six hours, airline blames weather: review', () {
      expect(check(hours: 8, extraordinary: true).outcome, Outcome.maybe);
    });
    test('no fare given: states the rate, never a figure', () {
      final r = check(hours: 7);
      expect(r.amount, '25% of your ticket price');
      expect(r.estimateValue, '25% of ticket price');
    });
  });

  group('international delay', () {
    test('two to four hours: 30% of the fare', () {
      final r = check(type: FlightType.international, hours: 3, fare: 500000);
      expect(r.outcome, Outcome.yes);
      expect(r.amount, '₦150,000');
    });
    test('beyond four hours: review, not a promise', () {
      final r = check(type: FlightType.international, hours: 5, fare: 500000);
      expect(r.outcome, Outcome.maybe);
      expect(r.amount, '₦150,000');
    });
  });

  group('cancellation', () {
    test('domestic with 24 hours notice: no compensation', () {
      expect(check(disruption: Disruption.cancellation, notice: true).outcome,
          Outcome.no);
    });
    test('domestic at short notice: 25%', () {
      final r = check(
          disruption: Disruption.cancellation, notice: false, fare: 60000);
      expect(r.outcome, Outcome.yes);
      expect(r.amount, '₦15,000');
    });
    test('notice not known: review', () {
      expect(check(disruption: Disruption.cancellation).outcome, Outcome.maybe);
    });
    test('international at short notice: 30%', () {
      final r = check(
          disruption: Disruption.cancellation,
          type: FlightType.international,
          notice: false,
          fare: 1000000);
      expect(r.amount, '₦300,000');
    });
  });

  test('denied boarding: compensation at the standard rate', () {
    final r = check(disruption: Disruption.deniedBoarding, fare: 40000);
    expect(r.outcome, Outcome.yes);
    expect(r.amount, '₦10,000');
  });

  group('downgrade', () {
    test('domestic: fare difference plus 30%', () {
      final r = check(disruption: Disruption.downgrade, fare: 100000);
      expect(r.amount, 'Fare difference + ₦30,000');
    });
    test('international: fare difference plus 50%', () {
      final r = check(
          disruption: Disruption.downgrade,
          type: FlightType.international,
          fare: 100000);
      expect(r.amount, 'Fare difference + ₦50,000');
    });
  });

  test('fractional amounts keep their kobo', () {
    expect(check(hours: 7, fare: 33333).amount, '₦8,333.25');
  });
}
