import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/data/database/app_database.dart';
import '../../../shared/providers/category_list_provider.dart';
import '../../../shared/providers/transaction_list_provider.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/category_selector_sheet.dart';
import '../../../shared/widgets/receipt_group_tile.dart';
import '../../../shared/widgets/transaction_form_sheet.dart';
import '../../../shared/widgets/transaction_tile.dart';
import 'transaction_detail_screen.dart';

// Représentation d'un item dans la liste de l'Historique
sealed class _HistoryItem {}

class _SingleTx extends _HistoryItem {
  _SingleTx(this.transaction);
  final Transaction transaction;
}

class _ReceiptGroup extends _HistoryItem {
  _ReceiptGroup(this.transactions);
  final List<Transaction> transactions;
}

List<_HistoryItem> _buildItems(List<Transaction> txs) {
  final items = <_HistoryItem>[];
  // Grouper par receiptId en préservant l'ordre date desc
  final seen = <String>{};
  final groups = <String, List<Transaction>>{};

  for (final tx in txs) {
    if (tx.receiptId == null) {
      items.add(_SingleTx(tx));
    } else {
      final rid = tx.receiptId!;
      if (!seen.contains(rid)) {
        seen.add(rid);
        groups[rid] = [];
        // placeholder pour préserver l'ordre
        items.add(_ReceiptGroup(groups[rid]!));
      }
      groups[rid]!.add(tx);
    }
  }
  return items;
}

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  static const _sheetShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(transactionListProvider);
    final catAsync = ref.watch(categoryListProvider);

    final categoryMap = {
      for (final c in catAsync.asData?.value ?? <Category>[]) c.id: c,
    };

    return txAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, e) => const Center(
        child: Icon(Icons.error_outline, color: AppColors.danger, size: 48),
      ),
      data: (transactions) {
        if (transactions.isEmpty) {
          return _EmptyState(onAddTap: () => _runFormLoop(context));
        }

        final items = _buildItems(transactions);

        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, i) => const Divider(
            color: AppColors.border,
            height: 1,
            indent: 16,
            endIndent: 16,
          ),
          itemBuilder: (_, i) {
            final item = items[i];
            return switch (item) {
              _SingleTx(:final transaction) => TransactionTile(
                transaction: transaction,
                category: categoryMap[transaction.categoryId],
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => TransactionDetailScreen(
                      transaction: transaction,
                      category: categoryMap[transaction.categoryId],
                    ),
                  ),
                ),
              ),
              _ReceiptGroup(:final transactions) => ReceiptGroupTile(
                key: ValueKey(transactions.first.receiptId),
                transactions: transactions,
                categoryMap: categoryMap,
                onLineTap: (tx) => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => TransactionDetailScreen(
                      transaction: tx,
                      category: categoryMap[tx.categoryId],
                    ),
                  ),
                ),
              ),
            };
          },
        );
      },
    );
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAddTap});

  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.account_balance_wallet_outlined,
              color: AppColors.accent,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune transaction pour le moment.',
              style: GoogleFonts.urbanist(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: onAddTap,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Ajouter une transaction',
                  style: GoogleFonts.urbanist(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
