import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'transaction_list_provider.dart';

final monthlyVariationProvider = Provider<int>((ref) {
  final transactions = ref.watch(transactionListProvider).asData?.value ?? [];
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;

  return transactions
      .where((t) => t.date >= startOfMonth)
      .fold<int>(0, (acc, t) {
    return t.type == 'revenu' ? acc + t.amountCents : acc - t.amountCents;
  });
});
