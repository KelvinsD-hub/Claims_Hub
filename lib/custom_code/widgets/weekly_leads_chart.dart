// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart';
import '/flutter_flow/custom_functions.dart';
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:fl_chart/fl_chart.dart';

class WeeklyLeadsChart extends StatefulWidget {
  const WeeklyLeadsChart({
    super.key,
    this.width,
    this.height,
    required this.leadCounts,
  });

  final double? width;
  final double? height;

  /// Lead counts for the last 7 days (oldest → newest).
  /// If fewer than 7 are supplied the remainder is zero-padded on the left.
  final List<int> leadCounts;

  @override
  State<WeeklyLeadsChart> createState() => _WeeklyLeadsChartState();
}

class _WeeklyLeadsChartState extends State<WeeklyLeadsChart> {
  // Matches Firestore weekly_lead_counts index: 0=Sun … 6=Sat (JS Date.getDay())
  static const _days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  List<FlSpot> get _spots {
    final raw = widget.leadCounts;
    final padded = raw.length >= 7
        ? raw.sublist(raw.length - 7)
        : [...List.filled(7 - raw.length, 0), ...raw];
    return List.generate(7, (i) => FlSpot(i.toDouble(), padded[i].toDouble()));
  }

  double get _maxY {
    if (widget.leadCounts.isEmpty) return 10;
    final max = widget.leadCounts.reduce((a, b) => a > b ? a : b);
    return (max * 1.4).ceilToDouble().clamp(5.0, double.infinity);
  }

  @override
  Widget build(BuildContext context) {
    final primary = FlutterFlowTheme.of(context).primary;
    final secondaryText = FlutterFlowTheme.of(context).secondaryText;
    final interval = (_maxY / 4).ceilToDouble().clamp(1.0, double.infinity);

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: 6,
          minY: 0,
          maxY: _maxY,
          clipData: const FlClipData.all(),

          // — Grid: horizontal subtle lines only —
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            drawHorizontalLine: true,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (_) => FlLine(
              color: Colors.grey.withOpacity(0.12),
              strokeWidth: 1,
            ),
          ),

          // — Border: bottom + left axis lines only —
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom:
                  BorderSide(color: Colors.grey.withOpacity(0.3), width: 1),
              left: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1),
            ),
          ),

          // — Axis labels —
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 1,
                getTitlesWidget: (value, _) {
                  final idx = value.toInt();
                  if (idx < 0 || idx > 6) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _days[idx],
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: secondaryText,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: interval,
                getTitlesWidget: (value, meta) {
                  if (value == 0 || value == meta.max) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: secondaryText,
                    ),
                  );
                },
              ),
            ),
          ),

          // — Tooltip —
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => primary.withOpacity(0.88),
              tooltipBorderRadius: BorderRadius.circular(8),
              tooltipPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              getTooltipItems: (spots) => spots
                  .map((s) => LineTooltipItem(
                        '${s.y.toInt()} leads',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ))
                  .toList(),
            ),
          ),

          // — Line + gradient fill —
          lineBarsData: [
            LineChartBarData(
              spots: _spots,
              isCurved: true,
              curveSmoothness: 0.35,
              preventCurveOverShooting: true,
              color: primary,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                  radius: 3.5,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: primary,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    primary.withOpacity(0.22),
                    primary.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
