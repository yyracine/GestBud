import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/providers/category_spending_provider.dart';
import '../../../shared/theme/app_colors.dart';
import '../widgets/balance_chart.dart';
import '../widgets/category_spending_tile.dart';
import '../widgets/period_selector.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(categorySpendingProvider);

    return Column(
      children: [
        const PeriodSelector(),
        const Divider(color: AppColors.border, height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              // Section FR-18 : Postes de dépense
              _SectionHeader(title: 'Postes de dépense'),
              if (entries.isEmpty)
                const _EmptySection(
                  message: 'Aucune dépense sur cette période.',
                )
              else
                ...entries.map((e) => CategorySpendingTile(entry: e)),
              const SizedBox(height: 24),
              // Section FR-19 : Graphique solde
              _SectionHeader(title: 'Évolution du solde'),
              const BalanceChart(),
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

