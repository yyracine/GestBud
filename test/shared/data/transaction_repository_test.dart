import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestbud/shared/data/database/app_database.dart';
import 'package:gestbud/shared/data/transaction_repository.dart';

void main() {
  late AppDatabase db;
  late TransactionRepository repo;
  late String catId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = TransactionRepository(db);
    final cats = await db.categoryDao.getAll();
    catId = cats.first.id;
  });

  tearDown(() async => db.close());

  Future<Transaction> insertOne({
    String type = 'depense',
    int amountCents = 5000,
    String? note,
    int? date,
    String? receiptId,
  }) async {
    final d = date ?? DateTime.now().millisecondsSinceEpoch;
    await repo.insert(
      type: type,
      amountCents: amountCents,
      categoryId: catId,
      date: d,
      note: note,
      receiptId: receiptId,
    );
    final txs = await db.transactionDao.getAll();
    return txs.first;
  }

  group('TransactionRepository.insert()', () {
    test('crée une transaction avec le bon type et montant', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await repo.insert(
        type: 'revenu',
        amountCents: 50000,
        categoryId: catId,
        date: now,
      );

      final txs = await db.transactionDao.getAll();
      expect(txs.length, 1);
      expect(txs.first.type, 'revenu');
      expect(txs.first.amountCents, 50000);
      expect(txs.first.categoryId, catId);
    });

    test('génère un UUID v4 unique pour chaque transaction', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await repo.insert(type: 'depense', amountCents: 1000, categoryId: catId, date: now);
      await repo.insert(type: 'revenu', amountCents: 2000, categoryId: catId, date: now);

      final txs = await db.transactionDao.getAll();
      expect(txs.length, 2);
      expect(txs[0].id, isNot(equals(txs[1].id)));
      // UUID v4 format: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
      expect(txs[0].id, matches(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'));
    });

    test('persiste la note quand elle est fournie', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await repo.insert(
        type: 'depense',
        amountCents: 5000,
        categoryId: catId,
        date: now,
        note: 'Courses du marché',
      );

      final txs = await db.transactionDao.getAll();
      expect(txs.first.note, 'Courses du marché');
    });

    test('laisse note null quand non fournie', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await repo.insert(type: 'depense', amountCents: 100, categoryId: catId, date: now);

      final txs = await db.transactionDao.getAll();
      expect(txs.first.note, isNull);
    });

    test('persiste la date en millisecondes epoch', () async {
      final date = DateTime(2026, 6, 15).millisecondsSinceEpoch;
      await repo.insert(type: 'depense', amountCents: 3000, categoryId: catId, date: date);

      final txs = await db.transactionDao.getAll();
      expect(txs.first.date, date);
    });

    test('type depense est stocké correctement', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await repo.insert(type: 'depense', amountCents: 8000, categoryId: catId, date: now);

      final txs = await db.transactionDao.getAll();
      expect(txs.first.type, 'depense');
    });
  });

  group('TransactionRepository.update()', () {
    test('modifie le type et le montant', () async {
      final tx = await insertOne(type: 'depense', amountCents: 10000);

      await repo.update(Transaction(
        id: tx.id,
        type: 'revenu',
        amountCents: 25000,
        currency: tx.currency,
        categoryId: tx.categoryId,
        receiptId: tx.receiptId,
        note: tx.note,
        date: tx.date,
        createdAt: tx.createdAt,
      ));

      final updated = (await db.transactionDao.getAll()).first;
      expect(updated.type, 'revenu');
      expect(updated.amountCents, 25000);
    });

    test('modifie la note (null → valeur puis valeur → null)', () async {
      final tx = await insertOne(note: null);

      await repo.update(Transaction(
        id: tx.id, type: tx.type, amountCents: tx.amountCents,
        currency: tx.currency, categoryId: tx.categoryId,
        receiptId: tx.receiptId, note: 'Ajoutée',
        date: tx.date, createdAt: tx.createdAt,
      ));
      expect((await db.transactionDao.getAll()).first.note, 'Ajoutée');

      final updated = (await db.transactionDao.getAll()).first;
      await repo.update(Transaction(
        id: updated.id, type: updated.type, amountCents: updated.amountCents,
        currency: updated.currency, categoryId: updated.categoryId,
        receiptId: updated.receiptId, note: null,
        date: updated.date, createdAt: updated.createdAt,
      ));
      expect((await db.transactionDao.getAll()).first.note, isNull);
    });

    test('modifie la date', () async {
      final tx = await insertOne(date: DateTime(2026, 1, 1).millisecondsSinceEpoch);
      final newDate = DateTime(2026, 6, 15).millisecondsSinceEpoch;

      await repo.update(Transaction(
        id: tx.id, type: tx.type, amountCents: tx.amountCents,
        currency: tx.currency, categoryId: tx.categoryId,
        receiptId: tx.receiptId, note: tx.note,
        date: newDate, createdAt: tx.createdAt,
      ));

      expect((await db.transactionDao.getAll()).first.date, newDate);
    });

    test('préserve les champs non modifiés (currency, receiptId, createdAt)', () async {
      final tx = await insertOne(receiptId: 'receipt-abc');

      await repo.update(Transaction(
        id: tx.id, type: 'revenu', amountCents: 1000,
        currency: tx.currency, categoryId: tx.categoryId,
        receiptId: tx.receiptId, note: tx.note,
        date: tx.date, createdAt: tx.createdAt,
      ));

      final updated = (await db.transactionDao.getAll()).first;
      expect(updated.currency, 'XOF');
      expect(updated.receiptId, 'receipt-abc');
      expect(updated.createdAt, tx.createdAt);
    });
  });

  group('TransactionRepository.delete()', () {
    test('supprime la transaction par id', () async {
      final tx = await insertOne();
      expect((await db.transactionDao.getAll()).length, 1);

      await repo.delete(tx.id);

      expect((await db.transactionDao.getAll()).length, 0);
    });

    test("n'affecte pas les autres transactions", () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await repo.insert(type: 'depense', amountCents: 1000, categoryId: catId, date: now);
      await repo.insert(type: 'revenu', amountCents: 2000, categoryId: catId, date: now);

      final txs = await db.transactionDao.getAll();
      expect(txs.length, 2);

      await repo.delete(txs.first.id);

      final remaining = await db.transactionDao.getAll();
      expect(remaining.length, 1);
      expect(remaining.first.id, txs.last.id);
    });

    test('supprime une transaction appartenant à un reçu sans toucher les autres lignes', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await repo.insert(type: 'depense', amountCents: 500, categoryId: catId, date: now, receiptId: 'rcpt-1');
      await repo.insert(type: 'depense', amountCents: 800, categoryId: catId, date: now, receiptId: 'rcpt-1');

      final txs = await db.transactionDao.getAll();
      await repo.delete(txs.first.id);

      final remaining = await db.transactionDao.getAll();
      expect(remaining.length, 1);
      expect(remaining.first.receiptId, 'rcpt-1');
    });
  });
}
