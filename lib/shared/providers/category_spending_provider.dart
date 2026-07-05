import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/app_database.dart';
import 'category_list_provider.dart';
import 'selected_period_provider.dart';
import 'transaction_list_provider.dart';

class CategorySpendingEntry {
  const CategorySpendingEntry({
    required this.categoryId,
    required this.categoryName,
    required this.icon,
    required this.colorToken,
    required this.currentAmountCents,
  });

  final String categoryId;
  final String categoryName;
  final String icon;
  final String colorToken;
  final int currentAmountCents;
}

/// Postes de dépense de la période sélectionnée, triés par montant décroissant.
/// Catégories sans dépense sur la période exclues (AC-2).
final categorySpendingProvider = Provider<List<CategorySpendingEntry>>((ref) {
  final period = ref.watch(selectedPeriodProvider);
  final allTx = ref.watch(transactionListProvider).asData?.value ?? <Transaction>[];
  final cats = ref.watch(categoryListProvider).asData?.value ?? <Category>[];

  final totals = computeSpendingTotals(allTx, period);
  return buildCategorySpendingEntries(totals, cats);
});

/// Calcule les dépenses par catégorie pour une [period] — utilitaire pur testable.
/// Retourne `{ categoryId → amountCents }`.
Map<String, int> computeSpendingTotals(
  List<Transaction> transactions,
  DateTimeRange period,
) {
  final startMs = period.start.millisecondsSinceEpoch;
  final endMs = DateTime(
    period.end.year,
    period.end.month,
    period.end.day,
    23,
    59,
    59,
  ).millisecondsSinceEpoch;

  final totals = <String, int>{};
  for (final t in transactions) {
    if (t.type != 'depense') continue;
    if (t.date < startMs || t.date > endMs) continue;
    totals[t.categoryId] = (totals[t.categoryId] ?? 0) + t.amountCents;
  }
  return totals;
}

/// Joint les totaux avec les catégories, trie par montant décroissant.
/// Catégories orphelines (non présentes dans [cats]) exclues.
List<CategorySpendingEntry> buildCategorySpendingEntries(
  Map<String, int> totals,
  List<Category> cats,
) {
  final catById = {for (final c in cats) c.id: c};
  return totals.entries
      .where((e) => catById.containsKey(e.key))
      .map((e) {
        final cat = catById[e.key]!;
        return CategorySpendingEntry(
          categoryId: e.key,
          categoryName: cat.name,
          icon: cat.icon,
          colorToken: cat.colorToken,
          currentAmountCents: e.value,
        );
      })
      .toList()
    ..sort((a, b) => b.currentAmountCents.compareTo(a.currentAmountCents));
}
