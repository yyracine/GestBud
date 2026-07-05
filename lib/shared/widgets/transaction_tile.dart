import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../data/database/app_database.dart';
import '../theme/app_colors.dart';
import '../utils/category_utils.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    this.category,
    this.onTap,
  });

  final Transaction transaction;
  final Category? category;
  final VoidCallback? onTap;

  static final _dateFormat = DateFormat('dd/MM/yyyy', 'fr');

  static String _formatCents(int cents) {
    final units = cents ~/ 100;
    final s = units.toString();
    final result = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) {
        result.write(' ');
      }
      result.write(s[i]);
    }
    return result.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isRevenu = transaction.type == 'revenu';
    final sign = isRevenu ? '+' : '−';
    final amountColor = isRevenu ? AppColors.success : AppColors.danger;
    final formattedAmount = _formatCents(transaction.amountCents);
    final dateStr = _dateFormat.format(
      DateTime.fromMillisecondsSinceEpoch(transaction.date),
    );
    final label = (transaction.note?.isNotEmpty ?? false)
        ? transaction.note!
        : (isRevenu ? 'Revenu' : 'Dépense');
    final categoryName = category?.name ?? 'Catégorie';

    return Semantics(
      label: '$categoryName, $label, $sign${_formatCents(transaction.amountCents)} francs CFA, $dateStr',
      button: onTap != null,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _Pastille(category: category),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.urbanist(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateStr,
                        style: GoogleFonts.urbanist(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$sign$formattedAmount FCFA',
                  style: GoogleFonts.urbanist(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: amountColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Pastille extends StatelessWidget {
  const _Pastille({this.category});
  final Category? category;

  @override
  Widget build(BuildContext context) {
    if (category == null) {
      return Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: AppColors.surfaceRaised,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.category, color: AppColors.textSecondary, size: 20),
      );
    }

    final (bg, fg) = CategoryUtils.pastilleColors(category!.colorToken);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(CategoryUtils.iconData(category!.icon), color: fg, size: 20),
    );
  }
}
