import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:uuid/uuid.dart';

import 'daos/category_dao.dart';
import 'daos/settings_dao.dart';
import 'daos/transaction_dao.dart';

part 'app_database.g.dart';

// UUID v5 OID namespace — RFC 4122
const _kOidNamespace = '6ba7b812-9dad-11d1-80b4-00c04fd430c8';

class AppSettings extends Table {
  TextColumn get id => text()();
  TextColumn get currency => text().withDefault(const Constant('XOF'))();
  IntColumn get firstLoginAt => integer().nullable()();
  BoolColumn get onboardingShown => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  BoolColumn get isPredefined => boolean().withDefault(const Constant(false))();
  TextColumn get icon => text()();
  TextColumn get colorToken => text()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();
  IntColumn get amountCents => integer()();
  TextColumn get currency => text().withDefault(const Constant('XOF'))();
  TextColumn get categoryId => text().references(Categories, #id)();
  TextColumn get receiptId => text().nullable()();
  TextColumn get note => text().nullable()();
  IntColumn get date => integer()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [AppSettings, Categories, Transactions],
  daos: [CategoryDao, TransactionDao, SettingsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'gestbud'));

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await seedPredefinedCategories();
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<void> deleteCustomCategoryWithReassign(String categoryId) async {
    await transaction(() async {
      final autre = await categoryDao.findByName('Autre');
      if (autre == null) return;
      await transactionDao.reassignToCategory(categoryId, autre.id);
      await categoryDao.deleteCategory(categoryId);
    });
  }

  Future<void> seedPredefinedCategories() async {
    // UUID v5 déterministe (namespace OID + nom) → insertOrIgnore idempotent
    const uuidGen = Uuid();
    final now = DateTime.now().millisecondsSinceEpoch;

    final rows = [
      _catCompanion(uuidGen, 'Alimentation', 'restaurant', 'success', now),
      _catCompanion(uuidGen, 'Transport', 'directions_bus', 'accent', now),
      _catCompanion(uuidGen, 'Santé & Pharmacie', 'local_hospital', 'danger', now),
      _catCompanion(uuidGen, 'Hygiène & Entretien', 'cleaning_services', 'text-secondary', now),
      _catCompanion(uuidGen, 'Logement & Factures', 'home', 'warning', now),
      _catCompanion(uuidGen, 'Éducation', 'school', 'accent', now),
      _catCompanion(uuidGen, 'Loisirs & Sorties', 'celebration', 'success', now),
      _catCompanion(uuidGen, 'Habillement', 'checkroom', 'text-secondary', now),
      _catCompanion(uuidGen, 'Transferts & Épargne', 'savings', 'accent', now),
      _catCompanion(uuidGen, 'Autre', 'more_horiz', 'text-secondary', now),
    ];

    await batch((b) {
      b.insertAll(categories, rows, mode: InsertMode.insertOrIgnore);
    });
  }

  CategoriesCompanion _catCompanion(
    Uuid uuidGen,
    String name,
    String icon,
    String colorToken,
    int now,
  ) {
    return CategoriesCompanion.insert(
      id: uuidGen.v5(_kOidNamespace, 'gestbud.category.$name'),
      name: name,
      isPredefined: const Value(true),
      icon: icon,
      colorToken: colorToken,
      createdAt: now,
    );
  }
}
