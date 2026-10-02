/// Counting leads, claims and outcomes over time for the dashboard's trend
/// charts: by week, by month or by year.
///
/// Pure, so it can be tested without Firebase.

enum TrendPeriod { week, month, year }

/// One stretch of time on a chart: from [start] up to the next bucket's start.
class TrendBucket {
  const TrendBucket(this.start, this.label);
  final DateTime start;

  /// What the chart writes under it: "4 Aug", "Aug 26", "2026".
  final String label;
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// The buckets ending with the one [now] is in, oldest first: the last 12
/// weeks (each starting on a Sunday), the last 12 months, or each year from
/// [earliest] (at most the last 6; at least this year and last).
List<TrendBucket> trendBuckets(TrendPeriod period, DateTime now,
    {DateTime? earliest}) {
  final today = DateTime(now.year, now.month, now.day);
  switch (period) {
    case TrendPeriod.week:
      // DateTime.weekday is Mon=1 … Sun=7; % 7 gives days since Sunday.
      final thisWeek = today.subtract(Duration(days: today.weekday % 7));
      return [
        for (var i = 11; i >= 0; i--)
          () {
            final start =
                DateTime(thisWeek.year, thisWeek.month, thisWeek.day - 7 * i);
            return TrendBucket(
                start, '${start.day} ${_months[start.month - 1]}');
          }(),
      ];
    case TrendPeriod.month:
      return [
        for (var i = 11; i >= 0; i--)
          () {
            final start = DateTime(now.year, now.month - i);
            return TrendBucket(start,
                '${_months[start.month - 1]} ${'${start.year}'.substring(2)}');
          }(),
      ];
    case TrendPeriod.year:
      var first = earliest?.year ?? now.year - 1;
      if (first > now.year - 1) first = now.year - 1;
      if (first < now.year - 5) first = now.year - 5;
      return [
        for (var y = first; y <= now.year; y++) TrendBucket(DateTime(y), '$y'),
      ];
  }
}

/// How many of [dates] fall in each of [buckets]. Dates before the first
/// bucket, or missing, are not counted.
List<int> countIntoBuckets(
    List<TrendBucket> buckets, Iterable<DateTime?> dates) {
  final counts = List<int>.filled(buckets.length, 0);
  for (final at in dates) {
    if (at == null || buckets.isEmpty || at.isBefore(buckets.first.start)) {
      continue;
    }
    var i = buckets.length - 1;
    while (i > 0 && at.isBefore(buckets[i].start)) {
      i--;
    }
    counts[i]++;
  }
  return counts;
}
