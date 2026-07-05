import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/data/database/app_database.dart';
import '../../../shared/providers/selected_period_provider.dart';
import '../../../shared/providers/transaction_list_provider.dart';
import '../../../shared/theme/app_colors.dart';
import '../widgets/period_selector.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(selectedPeriodProvider);
    final txAsync = ref.watch(transactionListProvider);
    final allTx = txAsync.asData?.value ?? <Transaction>[];

    // Transactions filtrées pour la période sélectionnée (AC-6)
    final startMs = period.start.millisecondsSinceEpoch;
    final endMs = DateTime(
      period.end.year,
      period.end.month,
      period.end.day,
      23,
      59,
      59,
    ).millisecondsSinceEpoch;

    final periodTx = allTx
        .where((t) => t.date >= startMs && t.date <= endMs)
        .toList();

    final hasExpenses = periodTx.any((t) => t.type == 'depense');

    return Column(
      children: [
        const PeriodSelector(),
        const Divider(color: AppColors.border, height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              // Section FR-18 : Postes de dépense (Story 4.2)
              _SectionHeader(title: 'Postes de dépense'),
              if (!hasExpenses)
                const _EmptySection(
                  message: 'Aucune dépense sur cette période.',
                )
              else
                const _ComingSoon(message: 'Postes de dépense — Story 4.2'),
              const SizedBox(height: 24),
              // Section FR-19 : Graphique solde (Story 4.3)
              _SectionHeader(title: 'Évolution du solde'),
              const _ComingSoon(message: 'Graphique — Story 4.3'),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Text(
        title,
        style: GoogleFonts.urbanist(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: Text(
          message,
          style: GoogleFonts.urbanist(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _ComingSoon extends StatelessWidget {
  const _ComingSoon({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Text(
            message,
            style: GoogleFonts.urbanist(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
