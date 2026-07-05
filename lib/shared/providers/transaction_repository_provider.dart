import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/transaction_repository.dart';
import 'database_provider.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return TransactionRepository(db);
});
