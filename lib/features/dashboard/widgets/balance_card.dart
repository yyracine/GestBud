import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/providers/balance_provider.dart';
import '../../../shared/providers/monthly_variation_provider.dart';
import '../../../shared/theme/app_colors.dart';

class BalanceCard extends ConsumerWidget {
  const BalanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceCents = ref.watch(balanceProvider);
    final variationCents = ref.watch(monthlyVariationProvider);
    final sparklineData = ref.watch(sparklineDataProvider);

    final isNegative = balanceCents < 0;
    final amountColor = isNegative ? AppColors.danger : AppColors.textPrimary;
    final formattedAmount = _formatCents(balanceCents.abs());

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.accent, AppColors.accentGradient],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Solde courant',
            style: GoogleFonts.urbanist(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            label: '${balanceCents.abs() ~/ 100} francs CFA',
            excludeSemantics: true,
            child: Text(
              '$formattedAmount FCFA',
              style: GoogleFonts.urbanist(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: amountColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 4),
          _MonthlyVariation(variationCents: variationCents),
          const SizedBox(height: 16),
          _SparklineChart(data: sparklineData),
        ],
      ),
    );
  }

  static String _formatCents(int cents) {
    final units = cents ~/ 100;
    final s = units.toString();
    final result = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) {
        result.write(' '); // espace fine insécable
      }
      result.write(s[i]);
    }
    return result.toString();
  }
}

class _MonthlyVariation extends StatelessWidget {
  const _MonthlyVariation({required this.variationCents});
  final int variationCents;

  @override
  Widget build(BuildContext context) {
    if (variationCents == 0) return const SizedBox.shrink();

    final isPositive = variationCents > 0;
    final color = isPositive ? AppColors.success : AppColors.danger;
    final sign = isPositive ? '+' : '−';
    final amount = BalanceCard._formatCents(variationCents.abs());

    return Text(
      '$sign$amount FCFA ce mois',
      style: GoogleFonts.urbanist(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: color,
      ),
    );
  }
}

class _SparklineChart extends StatelessWidget {
  const _SparklineChart({required this.data});
  final List<int> data;

  @override
  Widget build(BuildContext context) {
    if (data.length < 2) return const SizedBox(height: 40);
    return SizedBox(
      height: 40,
      child: CustomPaint(
        painter: _SparklinePainter(data),
        size: const Size(double.infinity, 40),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter(this.data);
  final List<int> data;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final minVal = data.reduce(min).toDouble();
    final maxVal = data.reduce(max).toDouble();
    final range = maxVal - minVal;

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    for (var i = 0; i < data.length; i++) {
      final x = size.width * i / (data.length - 1);
      final normalizedY = range > 0 ? (data[i] - minVal) / range : 0.5;
      final y = size.height * (1.0 - normalizedY);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SparklinePainter oldDelegate) =>
      oldDelegate.data != data;
}
