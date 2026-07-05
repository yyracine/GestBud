import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/providers/daily_balance_provider.dart';
import '../../../shared/theme/app_colors.dart';

class BalanceChart extends ConsumerWidget {
  const BalanceChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final points = ref.watch(dailyBalanceProvider);

    if (points.isEmpty) return const SizedBox(height: 180);

    final spots = [
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].balanceCents / 100),
    ];

    var minY = spots.first.y;
    var maxY = spots.first.y;
    for (final s in spots) {
      if (s.y < minY) minY = s.y;
      if (s.y > maxY) maxY = s.y;
    }
    final rangeY = maxY - minY;
    final paddingY = rangeY == 0 ? 5000.0 : rangeY * 0.15;
    final effectiveMinY = minY - paddingY;
    final effectiveMaxY = maxY + paddingY;

    final xInterval = (points.length - 1).toDouble().clamp(1.0, double.infinity);
    final yInterval = ((effectiveMaxY - effectiveMinY) / 3)
        .clamp(1.0, double.infinity);

    return Semantics(
      label: _trendLabel(points),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: (points.length - 1).toDouble(),
              minY: effectiveMinY,
              maxY: effectiveMaxY,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  color: AppColors.accent,
                  barWidth: 2,
                  isCurved: false,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.accent.withValues(alpha: 0.08),
                  ),
                ),
              ],
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: 0,
                    color: AppColors.border,
                    strokeWidth: 1,
                  ),
                ],
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: xInterval,
                    getTitlesWidget: (value, meta) =>
                        _buildXLabel(value, points, meta),
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 52,
                    interval: yInterval,
                    getTitlesWidget: _buildYLabel,
                  ),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => AppColors.surfaceRaised,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((s) {
                      final idx = s.x.toInt().clamp(0, points.length - 1);
                      final point = points[idx];
                      return LineTooltipItem(
                        '${point.date.day}/${point.date.month.toString().padLeft(2, '0')}\n'
                        '${_fmtFcfa(point.balanceCents)}',
                        GoogleFonts.urbanist(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildXLabel(
  double value,
  List<DailyBalancePoint> points,
  TitleMeta meta,
) {
  final idx = value.round();
  if (idx < 0 || idx >= points.length) return const SizedBox.shrink();
  final date = points[idx].date;
  return SideTitleWidget(
    axisSide: meta.axisSide,
    child: Text(
      '${date.day}/${date.month.toString().padLeft(2, '0')}',
      style: GoogleFonts.urbanist(
        fontSize: 10,
        color: AppColors.textSecondary,
      ),
    ),
  );
}

Widget _buildYLabel(double value, TitleMeta meta) {
  return SideTitleWidget(
    axisSide: meta.axisSide,
    child: Text(
      _fmtFcfaShort(value),
      style: GoogleFonts.urbanist(
        fontSize: 10,
        color: AppColors.textSecondary,
      ),
    ),
  );
}

String _fmtFcfaShort(double fcfa) {
  if (fcfa.abs() >= 1000000) {
    return '${(fcfa / 1000000).toStringAsFixed(1)}M';
  }
  if (fcfa.abs() >= 1000) {
    return '${(fcfa / 1000).toStringAsFixed(0)}k';
  }
  return fcfa.toInt().toString();
}

String _fmtFcfa(int cents) {
  final units = cents ~/ 100;
  final negative = units < 0;
  final s = units.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  return '${negative ? '−' : ''}${buf.toString()} FCFA';
}

String _trendLabel(List<DailyBalancePoint> points) {
  if (points.length < 2) return 'Graphique de solde';
  final delta = points.last.balanceCents - points.first.balanceCents;
  if (delta == 0) return 'Solde stable sur la période';
  final absFcfa = delta.abs() ~/ 100;
  if (delta > 0) return 'Solde en hausse de $absFcfa FCFA sur la période';
  return 'Solde en baisse de $absFcfa FCFA sur la période';
}
