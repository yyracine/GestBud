import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/providers/category_spending_provider.dart';
import '../../../shared/providers/monthly_comparison_provider.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/utils/category_utils.dart';

class CategorySpendingTile extends ConsumerWidget {
  const CategorySpendingTile({super.key, required this.entry});

  final CategorySpendingEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prevTotals = ref.watch(monthlyComparisonProvider);
    final prevCents = prevTotals[entry.categoryId];

    final (pastilleBg, pastilleFg) =
        CategoryUtils.pastilleColors(entry.colorToken);
    final iconData = CategoryUtils.iconData(entry.icon);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Pastille catégorie
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: pastilleBg,
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, color: pastilleFg, size: 20),
          ),
          const SizedBox(width: 12),
          // Nom + ligne de variation
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.categoryName,
                  style: GoogleFonts.urbanist(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                _VariationLine(
                  currentCents: entry.currentAmountCents,
                  prevCents: prevCents,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Montant courant : − X FCFA
          Text(
            '−${_fmt(entry.currentAmountCents)} FCFA',
            style: GoogleFonts.urbanist(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.danger,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

// Espace fine insécable Unicode U+202F
const _kThinNbSp = ' ';

/// Formate [cents] en unités avec séparateur de milliers (espace fine insécable).
String _fmt(int cents) {
  final units = cents ~/ 100;
  final s = units.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) {
      buf.write(_kThinNbSp);
    }
    buf.write(s[i]);
  }
  return buf.toString();
}

class _VariationLine extends StatelessWidget {
  const _VariationLine({
    required this.currentCents,
    required this.prevCents,
  });

  final int currentCents;
  final int? prevCents;

  @override
  Widget build(BuildContext context) {
    if (prevCents == null) {
      // AC-4 : mois précédent absent → « — »
      return Text(
        '—',
        style: GoogleFonts.urbanist(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      );
    }

    final prev = prevCents!;
    final diff = currentCents - prev;
    final pct = prev > 0 ? (diff.abs() * 100 / prev).round() : 0;

    if (diff == 0) {
      return Text(
        '= 0 FCFA · 0%',
        style: GoogleFonts.urbanist(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      );
    }

    final isIncrease = diff > 0;
    final arrow = isIncrease ? '↑' : '↓';
    // Hausse de dépense = mauvais (danger) · baisse = bon (success)
    final color = isIncrease ? AppColors.danger : AppColors.success;
    final sign = isIncrease ? '+' : '−';
    final label = '$arrow $sign${_fmt(diff.abs())} FCFA · $sign$pct%';

    return Text(
      label,
      style: GoogleFonts.urbanist(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: color,
      ),
    );
  }
}
