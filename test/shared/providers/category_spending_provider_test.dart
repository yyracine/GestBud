import 'package:flutter_test/flutter_test.dart';
import 'package:gestbud/shared/data/database/app_database.dart';
import 'package:gestbud/shared/providers/category_spending_provider.dart';
import 'package:gestbud/shared/providers/selected_period_provider.dart';

// ---------------------------------------------------------------------------
// Helpers de fabrication (objets Dart purs, sans Drift)
// ---------------------------------------------------------------------------

Category _cat(String id, String name, String icon, String colorToken) =>
    Category(
      id: id,
      name: name,
      isPredefined: true,
      icon: icon,
      colorToken: colorToken,
      createdAt: 0,
    );

Transaction _tx({
  required String id,
  required String type,
  required int amountCents,
  required String categoryId,
  required int date,
}) =>
    Transaction(
      id: id,
      type: type,
      amountCents: amountCents,
      currency: 'XOF',
      categoryId: categoryId,
      receiptId: null,
      note: null,
      date: date,
      createdAt: 0,
    );

int _ms(int year, int month, int day, [int hour = 12]) =>
    DateTime(year, month, day, hour).millisecondsSinceEpoch;

final _july2026 = monthRange(2026, 7);

// ---------------------------------------------------------------------------
// Catégories de test
// ---------------------------------------------------------------------------

final _catAlim = _cat('c-alim', 'Alimentation', 'restaurant', 'success');
final _catTransp = _cat('c-transp', 'Transport', 'directions_bus', 'accent');
final _catSante = _cat('c-sante', 'Santé', 'local_hospital', 'danger');

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // =========================================================================
  // computeSpendingTotals()  — logique de filtrage/cumul
  // =========================================================================
  group('computeSpendingTotals()', () {
    test('retourne map vide si aucune transaction', () {
      expect(computeSpendingTotals([], _july2026), isEmpty);
    });

    test('exclut les revenus', () {
      final result = computeSpendingTotals(
        [
          _tx(
            id: 't1',
            type: 'revenu',
            amountCents: 50000,
            categoryId: 'c-alim',
            date: _ms(2026, 7, 10),
          ),
        ],
        _july2026,
      );
      expect(result, isEmpty);
    });

    test('exclut les transactions hors période (avant start)', () {
      final result = computeSpendingTotals(
        [
          _tx(
            id: 't1',
            type: 'depense',
            amountCents: 10000,
            categoryId: 'c-alim',
            date: _ms(2026, 6, 30, 23), // 30 juin 23h — hors juillet
          ),
        ],
        _july2026,
      );
      expect(result, isEmpty);
    });

    test('exclut les transactions hors période (après end)', () {
      final result = computeSpendingTotals(
        [
          _tx(
            id: 't1',
            type: 'depense',
            amountCents: 10000,
            categoryId: 'c-alim',
            date: _ms(2026, 8, 1, 0), // 1er août — hors juillet
          ),
        ],
        _july2026,
      );
      expect(result, isEmpty);
    });

    test('inclut une transaction le premier jour à minuit (start boundary)', () {
      final startMs = _july2026.start.millisecondsSinceEpoch; // 1er juil 00h00
      final result = computeSpendingTotals(
        [
          _tx(
            id: 't1',
            type: 'depense',
            amountCents: 5000,
            categoryId: 'c-alim',
            date: startMs,
          ),
        ],
        _july2026,
      );
      expect(result['c-alim'], 5000);
    });

    test('inclut une transaction le dernier jour à 23h59:59 (end boundary)', () {
      final endMs = DateTime(2026, 7, 31, 23, 59, 59).millisecondsSinceEpoch;
      final result = computeSpendingTotals(
        [
          _tx(
            id: 't1',
            type: 'depense',
            amountCents: 7000,
            categoryId: 'c-alim',
            date: endMs,
          ),
        ],
        _july2026,
      );
      expect(result['c-alim'], 7000);
    });

    test('cumule plusieurs transactions de la même catégorie', () {
      final result = computeSpendingTotals(
        [
          _tx(
            id: 't1',
            type: 'depense',
            amountCents: 10000,
            categoryId: 'c-alim',
            date: _ms(2026, 7, 5),
          ),
          _tx(
            id: 't2',
            type: 'depense',
            amountCents: 8000,
            categoryId: 'c-alim',
            date: _ms(2026, 7, 20),
          ),
        ],
        _july2026,
      );
      expect(result['c-alim'], 18000);
    });

    test('sépare les totaux par catégorie', () {
      final result = computeSpendingTotals(
        [
          _tx(
            id: 't1',
            type: 'depense',
            amountCents: 30000,
            categoryId: 'c-transp',
            date: _ms(2026, 7, 10),
          ),
          _tx(
            id: 't2',
            type: 'depense',
            amountCents: 12000,
            categoryId: 'c-alim',
            date: _ms(2026, 7, 15),
          ),
        ],
        _july2026,
      );
      expect(result['c-transp'], 30000);
      expect(result['c-alim'], 12000);
    });
  });

  // =========================================================================
  // buildCategorySpendingEntries()  — jointure et tri
  // =========================================================================
  group('buildCategorySpendingEntries()', () {
    test('retourne liste vide si totaux vides', () {
      final result = buildCategorySpendingEntries({}, [_catAlim]);
      expect(result, isEmpty);
    });

    test('retourne liste vide si cats vides (catégorie orpheline)', () {
      final result = buildCategorySpendingEntries({'c-alim': 10000}, []);
      expect(result, isEmpty);
    });

    test('ignore les catégories orphelines (id absent des cats)', () {
      final result = buildCategorySpendingEntries(
        {'c-unknown': 10000},
        [_catAlim],
      );
      expect(result, isEmpty);
    });

    test('popule les champs depuis la catégorie correspondante', () {
      final result = buildCategorySpendingEntries(
        {'c-sante': 20000},
        [_catSante],
      );
      expect(result.length, 1);
      expect(result.first.categoryId, 'c-sante');
      expect(result.first.categoryName, 'Santé');
      expect(result.first.icon, 'local_hospital');
      expect(result.first.colorToken, 'danger');
      expect(result.first.currentAmountCents, 20000);
    });

    test('trie les postes par montant décroissant (AC-1)', () {
      final result = buildCategorySpendingEntries(
        {'c-alim': 5000, 'c-transp': 30000, 'c-sante': 15000},
        [_catAlim, _catTransp, _catSante],
      );
      expect(result.length, 3);
      expect(result[0].categoryId, 'c-transp'); // 30 000
      expect(result[1].categoryId, 'c-sante');  // 15 000
      expect(result[2].categoryId, 'c-alim');   // 5 000
    });

    test('catégorie avec dépense présente, autre absente du total → exclue (AC-2)', () {
      // Seulement c-alim dans les totaux → c-transp absent
      final result = buildCategorySpendingEntries(
        {'c-alim': 20000},
        [_catAlim, _catTransp],
      );
      expect(result.length, 1);
      expect(result.first.categoryId, 'c-alim');
    });
  });

}
