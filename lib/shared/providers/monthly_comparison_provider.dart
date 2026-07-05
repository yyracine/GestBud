import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/app_database.dart';
import 'category_spending_provider.dart';
import 'selected_period_provider.dart';
import 'transaction_list_provider.dart';

/// Dépenses par catégorie du mois calendaire précédant [selectedPeriodProvider].
/// Clé : `categoryId` · Valeur : total en centimes.
/// Map vide si aucune dépense ce mois.
final monthlyComparisonProvider = Provider<Map<String, int>>((ref) {
  final period = ref.watch(selectedPeriodProvider);
  final allTx =
      ref.watch(transactionListProvider).asData?.value ?? <Transaction>[];

  final prevPeriod = previousMonth(period);
  return computeSpendingTotals(allTx, prevPeriod);
});
