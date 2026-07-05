import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestbud/shared/data/database/app_database.dart';

void main() {
  group('SettingsDao.setOnboardingShown', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('crée la ligne et met onboardingShown à true', () async {
      await db.settingsDao.setOnboardingShown(true);
      final s = await db.settingsDao.getSettings();
      expect(s, isNotNull);
      expect(s!.onboardingShown, isTrue);
    });

    test('met onboardingShown à false si appelé avec false', () async {
      await db.settingsDao.setOnboardingShown(true);
      await db.settingsDao.setOnboardingShown(false);
      final s = await db.settingsDao.getSettings();
      expect(s!.onboardingShown, isFalse);
    });

    test('est idempotent — appels multiples true ne créent pas de doublons', () async {
      await db.settingsDao.setOnboardingShown(true);
      await db.settingsDao.setOnboardingShown(true);
      final all = await db.select(db.appSettings).get();
      expect(all.length, 1);
      expect(all.first.onboardingShown, isTrue);
    });
  });

  group('AppDatabase.onCreate', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('seeds exactly 10 predefined categories', () async {
      final cats = await db.select(db.categories).get();
      expect(cats.length, 10);
    });

    test('all seeded categories are marked isPredefined', () async {
      final cats = await db.select(db.categories).get();
      expect(cats.every((c) => c.isPredefined), isTrue);
    });

    test('seeds the 10 expected category names', () async {
      final cats = await db.select(db.categories).get();
      final names = cats.map((c) => c.name).toSet();
      expect(names, containsAll(<String>[
        'Alimentation',
        'Transport',
        'Santé & Pharmacie',
        'Hygiène & Entretien',
        'Logement & Factures',
        'Éducation',
        'Loisirs & Sorties',
        'Habillement',
        'Transferts & Épargne',
        'Autre',
      ]));
    });

    test('seeding is idempotent — second onCreate call does not duplicate', () async {
      await db.seedPredefinedCategories();
      final cats = await db.select(db.categories).get();
      expect(cats.length, 10);
    });

    test('all category IDs are non-empty strings', () async {
      final cats = await db.select(db.categories).get();
      expect(cats.every((c) => c.id.isNotEmpty), isTrue);
    });
  });
}
