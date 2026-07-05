import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../domain/receipt_line.dart';
import 'database/app_database.dart';

class TransactionRepository {
  TransactionRepository(this._db);
  final AppDatabase _db;

  static const _uuid = Uuid();

  Future<void> insert({
    required String type,
    required int amountCents,
    required String categoryId,
    required int date,
    String? note,
    String? receiptId,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.transactionDao.insertEntry(
      TransactionsCompanion.insert(
        id: _uuid.v4(),
        type: type,
        amountCents: amountCents,
        categoryId: categoryId,
        date: date,
        createdAt: now,
        note: Value(note),
        receiptId: Value(receiptId),
      ),
    );
  }

  Future<void> update(Transaction tx) async {
    await _db.transactionDao.updateEntry(
      TransactionsCompanion(
        id: Value(tx.id),
        type: Value(tx.type),
        amountCents: Value(tx.amountCents),
        categoryId: Value(tx.categoryId),
        date: Value(tx.date),
        createdAt: Value(tx.createdAt),
        note: Value(tx.note),
        receiptId: Value(tx.receiptId),
        currency: Value(tx.currency),
      ),
    );
  }

  Future<void> delete(String id) async {
    await _db.transactionDao.deleteById(id);
  }

  Future<void> insertReceiptLines(
    String receiptId,
    List<ReceiptLine> lines,
  ) async {
    if (lines.isEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final allCats = await _db.categoryDao.getAll();
    final catByName = {for (final c in allCats) c.name: c.id};
    final autreCatId = catByName['Autre']!;

    await _db.transaction(() async {
      for (final line in lines) {
        final categoryId = catByName[line.category] ?? autreCatId;
        await _db.transactionDao.insertEntry(
          TransactionsCompanion.insert(
            id: _uuid.v4(),
            type: 'depense',
            amountCents: line.amountCents,
            categoryId: categoryId,
            date: now,
            createdAt: now,
            note: Value(line.label),
            receiptId: Value(receiptId),
          ),
        );
      }
    });
  }
}
