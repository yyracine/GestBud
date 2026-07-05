import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/data/database/app_database.dart';
import '../../../shared/providers/database_provider.dart';
import '../../../shared/providers/settings_provider.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/category_selector_sheet.dart';
import '../../../shared/widgets/fab_menu_sheet.dart';
import '../../../shared/widgets/info_banner.dart';
import '../../../shared/widgets/transaction_form_sheet.dart';

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.child});

  final Widget child;

  static const _tabs = [
    ('/home', Icons.home_outlined, Icons.home, 'Accueil'),
    ('/history', Icons.receipt_long_outlined, Icons.receipt_long, 'Historique'),
    (
      '/dashboard',
      Icons.bar_chart_outlined,
      Icons.bar_chart,
      'Tableau de bord'
    ),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final idx = _tabs.indexWhere((t) => location.startsWith(t.$1));
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idx = _currentIndex(context);
    final onboardingShown = ref.watch(onboardingShownProvider);
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: Text(
          _tabs[idx].$4,
          style: GoogleFonts.urbanist(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.textSecondary),
            onPressed: () => context.push('/settings'),
            tooltip: 'Paramètres',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: child),
          if (!onboardingShown)
            InfoBanner(
              message: 'Tes données sont sur ton téléphone. Ne désinstalle pas l\'app.',
              onDismiss: () => ref
                  .read(databaseProvider)
                  .settingsDao
                  .setOnboardingShown(true),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: idx,
        onTap: (i) => context.go(_tabs[i].$1),
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: GoogleFonts.urbanist(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.urbanist(
          fontSize: 11,
          fontWeight: FontWeight.w400,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        items: _tabs
            .map(
              (t) => BottomNavigationBarItem(
                icon: Icon(t.$2),
                activeIcon: Icon(t.$3),
                label: t.$4,
              ),
            )
            .toList(),
      ),
      floatingActionButton: const _HomeFab(),
    );
  }
}

/// Gère la navigation FAB → FabMenuSheet → TransactionFormSheet ↔ CategorySelectorSheet.
/// Jamais deux bottom sheets empilés simultanément (UX-DR20).
class _HomeFab extends StatelessWidget {
  const _HomeFab();

  static const _sheetShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
  );

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _handleTap(context),
      backgroundColor: AppColors.accent,
      elevation: 4,
      child: const Icon(Icons.add, color: AppColors.textPrimary),
    );
  }

  Future<void> _handleTap(BuildContext context) async {
    final action = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: _sheetShape,
      builder: (_) => const FabMenuSheet(),
    );

    if (!context.mounted) return;

    if (action == 'scan_receipt') {
      context.push('/scan/entry');
    } else if (action == 'new_transaction') {
      await _runFormLoop(context);
    }
  }

  Future<void> _runFormLoop(
    BuildContext context, {
    TransactionFormData? savedData,
  }) async {
    if (!context.mounted) return;

    final result = await showModalBottomSheet<Object?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: _sheetShape,
      builder: (_) => TransactionFormSheet(savedData: savedData),
    );

    if (result is PickCategorySignal && context.mounted) {
      final category = await showModalBottomSheet<Category?>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.surface,
        shape: _sheetShape,
        builder: (_) => CategorySelectorSheet(
          selectedId: result.formData.category?.id,
        ),
      );

      if (context.mounted) {
        await _runFormLoop(
          context,
          savedData: result.formData.copyWith(
            category: category ?? result.formData.category,
          ),
        );
      }
    }
  }
}
