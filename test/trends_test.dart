import 'package:claims_hub/backend/services/trends.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // A Thursday.
  final now = DateTime(2026, 10, 1, 15, 30);

  test('weeks: the last twelve, starting on Sundays, ending with this one', () {
    final b = trendBuckets(TrendPeriod.week, now);
    expect(b.length, 12);
    expect(b.last.start, DateTime(2026, 9, 27));
    expect(b.last.label, '27 Sep');
    expect(b.first.start, DateTime(2026, 7, 12));
    expect(b.every((x) => x.start.weekday == DateTime.sunday), isTrue);
  });

  test('months: the last twelve, across the turn of the year', () {
    final b = trendBuckets(TrendPeriod.month, now);
    expect(b.length, 12);
    expect(b.first.start, DateTime(2025, 11));
    expect(b.first.label, 'Nov 25');
    expect(b.last.label, 'Oct 26');
  });

  test('years: from the first record, at least two, at most six', () {
    expect(trendBuckets(TrendPeriod.year, now).map((x) => x.label),
        ['2025', '2026']);
    expect(
        trendBuckets(TrendPeriod.year, now, earliest: DateTime(2024, 5))
            .map((x) => x.label),
        ['2024', '2025', '2026']);
    expect(trendBuckets(TrendPeriod.year, now, earliest: DateTime(2012)).length,
        6);
  });

  test('dates are counted into the bucket they fall in', () {
    final b = trendBuckets(TrendPeriod.month, now);
    final counts = countIntoBuckets(b, [
      DateTime(2026, 10, 1),
      DateTime(2026, 9, 30, 23, 59),
      DateTime(2026, 9, 1),
      DateTime(2025, 11, 1),
      DateTime(2025, 10, 31), // before the first bucket
      null,
    ]);
    expect(counts.last, 1);
    expect(counts[10], 2);
    expect(counts.first, 1);
    expect(counts.reduce((a, b) => a + b), 4);
  });
}
