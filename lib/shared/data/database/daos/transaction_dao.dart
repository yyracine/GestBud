import 'package:drift/drift.dart';

import '../app_database.dart';

part 'transaction_dao.g.dart';

@DriftAccessor(tables: [Transactions, Categories])
class TransactionDao extends DatabaseAccessor<AppDatabase> with _$TransactionDaoMixin {
  TransactionDao(super.db);

  Stream<List<Transaction>> watchAll() =>
      (select(transactions)..orderBy([(t) => OrderingTerm.desc(t.date)])).watch();

  Future<List<Transaction>> getAll() =>
      (select(transactions)..orderBy([(t) => OrderingTerm.desc(t.date)])).get();

  Future<int> insertEntry(TransactionsCompanion row) =>
      into(transactions).insert(row);

  Future<bool> updateEntry(TransactionsCompanion row) =>
      update(transactions).replace(row);

  Future<int> deleteById(String id) =>
      (delete(transactions)..where((t) => t.id.equals(id))).go();

  Future<void> reassignToCategory(String fromId, String toId) async {
    await (update(transactions)..where((t) => t.categoryId.equals(fromId)))
        .write(TransactionsCompanion(categoryId: Value(toId)));
  }
}
