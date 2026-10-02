import '/backend/backend.dart';
import '/backend/services/pipeline.dart';
import '/backend/services/trends.dart';
import '/components/work_ui.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Two series colours, checked for colour-blind separation and contrast on
/// both themes. Leads and claims on the line; won and lost on the bars.
const _blue = Color(0xFF2F7FD1);
const _gold = Color(0xFFB8860B);
const _green = Color(0xFF2F9E73);
const _orange = Color(0xFFD4662A);

/// The dashboard's trends: what came in (leads received, claims opened) as
/// lines, and how claims ended (won, lost) as bars, by week, month or year.
class TrendCharts extends StatefulWidget {
  const TrendCharts({super.key, required this.leads, required this.claims});

  final List<LeadsRecord> leads;
  final List<ClaimsRecord> claims;

  @override
  State<TrendCharts> createState() => _TrendChartsState();
}

class _TrendChartsState extends State<TrendCharts> {
  TrendPeriod _period = TrendPeriod.month;

  /// False for the first frame, so the charts grow in from zero.
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _shown = true);
    });
  }

  static DateTime? _date(dynamic v) => v is Timestamp ? v.toDate() : null;

  /// When a claim reached its outcome: the settlement or closing date, or
  /// failing those the last stage change.
  static DateTime? _closedAt(ClaimsRecord c) =>
      _date(c.snapshotData['settlement_date']) ??
      _date(c.snapshotData['closed_at']) ??
      _date(c.snapshotData['stage_changed_at']);

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final now = DateTime.now();
    final dates = [
      for (final l in widget.leads) l.createdAt,
      for (final c in widget.claims) c.createdAt,
    ].whereType<DateTime>();
    final earliest =
        dates.isEmpty ? null : dates.reduce((a, b) => a.isBefore(b) ? a : b);
    final buckets = trendBuckets(_period, now, earliest: earliest);

    final stage =
        (ClaimsRecord c) => canonicalStage(RecordKind.claim, c.claimStatus);
    final leadsIn =
        countIntoBuckets(buckets, widget.leads.map((l) => l.createdAt));
    final claimsIn =
        countIntoBuckets(buckets, widget.claims.map((c) => c.createdAt));
    final won = countIntoBuckets(
        buckets,
        widget.claims
            .where((c) =>
                stage(c) == ClaimStage.won || stage(c) == ClaimStage.paid)
            .map(_closedAt));
    final lost = countIntoBuckets(
        buckets,
        widget.claims
            .where((c) =>
                stage(c) == ClaimStage.lost || stage(c) == ClaimStage.withdrawn)
            .map(_closedAt));

    final span = switch (_period) {
      TrendPeriod.week => 'the last 12 weeks',
      TrendPeriod.month => 'the last 12 months',
      TrendPeriod.year => 'each year',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Trends',
                style: GoogleFonts.interTight(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w700,
                    color: theme.primaryText)),
            const SizedBox(width: 14.0),
            for (final (period, label) in const [
              (TrendPeriod.week, 'Weekly'),
              (TrendPeriod.month, 'Monthly'),
              (TrendPeriod.year, 'Yearly'),
            ]) ...[
              WorkChip(
                label: label,
                selected: _period == period,
                onTap: () => setState(() => _period = period),
              ),
              const SizedBox(width: 8.0),
            ],
          ],
        ),
        const SizedBox(height: 12.0),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _ChartPanel(
                title: 'What came in',
                subtitle: 'Leads received and claims opened, $span',
                legend: const [(_blue, 'Leads'), (_gold, 'Claims')],
                child: _Lines(
                  labels: [for (final b in buckets) b.label],
                  series: [
                    (_blue, 'leads', _shown ? leadsIn : _zeros(leadsIn)),
                    (_gold, 'claims', _shown ? claimsIn : _zeros(claimsIn)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14.0),
            Expanded(
              child: _ChartPanel(
                title: 'How claims ended',
                subtitle: 'Won and lost or withdrawn, $span',
                legend: const [(_green, 'Won'), (_orange, 'Lost or withdrawn')],
                child: _Bars(
                  labels: [for (final b in buckets) b.label],
                  series: [
                    (_green, 'won', _shown ? won : _zeros(won)),
                    (
                      _orange,
                      'lost or withdrawn',
                      _shown ? lost : _zeros(lost)
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static List<int> _zeros(List<int> like) => List<int>.filled(like.length, 0);
}

class _ChartPanel extends StatelessWidget {
  const _ChartPanel({
    required this.title,
    required this.subtitle,
    required this.legend,
    required this.child,
  });

  final String title;
  final String subtitle;
  final List<(Color, String)> legend;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      height: 340.0,
      padding: const EdgeInsets.fromLTRB(18.0, 16.0, 18.0, 12.0),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: theme.alternate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.interTight(
                            fontSize: 15.0,
                            fontWeight: FontWeight.w700,
                            color: theme.primaryText)),
                    Text(subtitle,
                        style: GoogleFonts.inter(
                            fontSize: 12.0, color: theme.secondaryText)),
                  ],
                ),
              ),
              for (final (color, label) in legend) ...[
                const SizedBox(width: 14.0),
                Container(
                    width: 10.0,
                    height: 10.0,
                    decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2.0))),
                const SizedBox(width: 6.0),
                Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 12.0, color: theme.primaryText)),
              ],
            ],
          ),
          const SizedBox(height: 16.0),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Axis styling shared by both charts: whole numbers up the side, the
/// bucket labels along the bottom (thinned out when there are many).
FlTitlesData _titles(BuildContext context, List<String> labels, double top) {
  final muted = GoogleFonts.inter(
      fontSize: 11.0, color: FlutterFlowTheme.of(context).secondaryText);
  final every = labels.length > 8 ? 2 : 1;
  return FlTitlesData(
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 28.0,
        interval: _step(top),
        getTitlesWidget: (value, meta) => value == meta.max
            ? const SizedBox.shrink()
            : Text('${value.toInt()}', style: muted),
      ),
    ),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 26.0,
        interval: 1.0,
        getTitlesWidget: (value, _) {
          final i = value.toInt();
          if (value != i || i < 0 || i >= labels.length) {
            return const SizedBox.shrink();
          }
          // Always label the latest bucket; thin out the others.
          if ((labels.length - 1 - i) % every != 0) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Text(labels[i], style: muted),
          );
        },
      ),
    ),
  );
}

/// A top for the scale a little above the largest value, never below 4.
double _top(List<List<int>> values) {
  final most = values.expand((v) => v).fold<int>(0, (m, v) => v > m ? v : m);
  return most < 4 ? 4.0 : (most * 1.2).ceilToDouble();
}

double _step(double top) => (top / 4).ceilToDouble().clamp(1.0, 1e9);

FlGridData _grid(BuildContext context, double top) => FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: _step(top),
      getDrawingHorizontalLine: (_) => FlLine(
        color: FlutterFlowTheme.of(context).alternate,
        strokeWidth: 1.0,
      ),
    );

FlBorderData _border(BuildContext context) => FlBorderData(
      show: true,
      border: Border(
          bottom: BorderSide(color: FlutterFlowTheme.of(context).alternate)),
    );

class _Lines extends StatelessWidget {
  const _Lines({required this.labels, required this.series});

  final List<String> labels;
  final List<(Color, String, List<int>)> series;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final top = _top([for (final s in series) s.$3]);
    return LineChart(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      LineChartData(
        minX: 0.0,
        maxX: (labels.length - 1).toDouble(),
        minY: 0.0,
        maxY: top,
        gridData: _grid(context, top),
        borderData: _border(context),
        titlesData: _titles(context, labels, top),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => theme.primaryText,
            tooltipBorderRadius: BorderRadius.circular(8.0),
            getTooltipItems: (spots) => [
              for (final s in spots)
                LineTooltipItem(
                  '${s.y.toInt()} ${series[s.barIndex].$2}'
                  '${s.barIndex == 0 ? '\n${labels[s.x.toInt()]}' : ''}',
                  GoogleFonts.inter(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w600,
                      color: theme.primaryBackground),
                ),
            ],
          ),
        ),
        lineBarsData: [
          for (final (color, _, values) in series)
            LineChartBarData(
              spots: [
                for (var i = 0; i < values.length; i++)
                  FlSpot(i.toDouble(), values[i].toDouble()),
              ],
              isCurved: true,
              curveSmoothness: 0.3,
              preventCurveOverShooting: true,
              color: color,
              barWidth: 2.0,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                  radius: 3.5,
                  color: color,
                  strokeWidth: 2.0,
                  strokeColor: theme.secondaryBackground,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Bars extends StatelessWidget {
  const _Bars({required this.labels, required this.series});

  final List<String> labels;
  final List<(Color, String, List<int>)> series;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final top = _top([for (final s in series) s.$3]);
    final width = labels.length > 8 ? 7.0 : 14.0;
    return BarChart(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      BarChartData(
        minY: 0.0,
        maxY: top,
        gridData: _grid(context, top),
        borderData: _border(context),
        titlesData: _titles(context, labels, top),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => theme.primaryText,
            tooltipBorderRadius: BorderRadius.circular(8.0),
            getTooltipItem: (group, _, rod, rodIndex) => BarTooltipItem(
              '${rod.toY.toInt()} ${series[rodIndex].$2}\n${labels[group.x]}',
              GoogleFonts.inter(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w600,
                  color: theme.primaryBackground),
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < labels.length; i++)
            BarChartGroupData(
              x: i,
              barsSpace: 2.0,
              barRods: [
                for (final (color, _, values) in series)
                  BarChartRodData(
                    toY: values[i].toDouble(),
                    color: color,
                    width: width,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(3.0)),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
