import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/providers/selected_period_provider.dart';
import '../../../shared/theme/app_colors.dart';
import 'custom_period_sheet.dart';

// Noms des mois en français (index 0 = janvier)
const _kFrMonths = [
  'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
  'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
];

class PeriodSelector extends ConsumerWidget {
  const PeriodSelector({super.key});

  static const _sheetShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(selectedPeriodProvider);
    final label = _formatLabel(period);

    return Container(
      color: AppColors.bg,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          // Flèche ◀
          IconButton(
            icon: const Icon(Icons.chevron_left, color: AppColors.textPrimary),
            iconSize: 28,
            splashRadius: 24,
            tooltip: 'Mois précédent',
            onPressed: () {
              ref
                  .read(selectedPeriodProvider.notifier)
                  .selectRange(previousMonth(period));
            },
          ),
          // Label période (tap → bottom sheet custom)
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _openCustomSheet(context, ref, period),
              child: Semantics(
                label: 'Période : $label. Appuyer pour choisir une période personnalisée.',
                button: true,
                child: Center(
                  child: Text(
                    label,
                    style: GoogleFonts.urbanist(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
          // Flèche ▶
          IconButton(
            icon: const Icon(Icons.chevron_right, color: AppColors.textPrimary),
            iconSize: 28,
            splashRadius: 24,
            tooltip: 'Mois suivant',
            onPressed: () {
              ref
                  .read(selectedPeriodProvider.notifier)
                  .selectRange(nextMonth(period));
            },
          ),
        ],
      ),
    );
  }

  Future<void> _openCustomSheet(
    BuildContext context,
    WidgetRef ref,
    DateTimeRange current,
  ) async {
    final result = await showModalBottomSheet<DateTimeRange?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: _sheetShape,
      builder: (_) => CustomPeriodSheet(current: current),
    );
    if (result != null) {
      ref.read(selectedPeriodProvider.notifier).selectRange(result);
    }
  }
}

/// Formate le label de période :
/// - mois complet → « Juillet 2026 »
/// - plage custom → « 01/06 – 15/07 »
String formatPeriodLabel(DateTimeRange period) => _formatLabel(period);

String _formatLabel(DateTimeRange period) {
  if (isFullMonth(period)) {
    return '${_kFrMonths[period.start.month - 1]} ${period.start.year}';
  }
  return '${_fmt(period.start)} – ${_fmt(period.end)}';
}

String _fmt(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
