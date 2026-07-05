import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'transaction_list_provider.dart';

final balanceProvider = Provider<int>((ref) {
  final transactions = ref.watch(transactionListProvider).asData?.value ?? [];
  return transactions.fold<int>(0, (acc, t) {
    return t.type == 'revenu' ? acc + t.amountCents : acc - t.amountCents;
  });
});

final sparklineDataProvider = Provider<List<int>>((ref) {
  final transactions = ref.watch(transactionListProvider).asData?.value ?? [];
  final today = DateTime.now();

  return List.generate(7, (i) {
    final dayOffset = 6 - i;
    final day = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: dayOffset));
    final endOfDay =
        DateTime(day.year, day.month, day.day, 23, 59, 59).millisecondsSinceEpoch;

    return transactions
        .where((t) => t.date <= endOfDay)
        .fold<int>(0, (acc, t) {
      return t.type == 'revenu' ? acc + t.amountCents : acc - t.amountCents;
    });
  });
});
