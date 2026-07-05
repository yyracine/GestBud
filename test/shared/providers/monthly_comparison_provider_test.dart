import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestbud/shared/data/database/app_database.dart';
import 'package:gestbud/shared/providers/category_spending_provider.dart';
import 'package:gestbud/shared/providers/selected_period_provider.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

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

int _ms(int year, int month, int day) =>
    DateTime(year, month, day, 12).millisecondsSinceEpoch;

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // =========================================================================
  // computeSpendingTotals() appliqué au mois précédent  — logique pure
  // =========================================================================
  group('mois précédent via computeSpendingTotals()', () {
    test('retourne map vide si aucune dépense le mois précédent', () {
      final prev = previousMonth(monthRange(2026, 7)); // = juin 2026
      expect(computeSpendingTotals([], prev), isEmpty);
    });

    test('exclut les revenus du mois précédent', () {
      final prev = previousMonth(monthRange(2026, 7));
      final result = computeSpendingTotals(
        [
          _tx(
            id: 't1',
            type: 'revenu',
            amountCents: 100000,
            categoryId: 'c1',
            date: _ms(2026, 6, 15),
          ),
        ],
        prev,
      );
      expect(result, isEmpty);
    });

    test('inclut uniquement les dépenses du mois calendaire précédent', () {
      final prev = previousMonth(monthRange(2026, 7)); // = juin 2026
      final result = computeSpendingTotals(
        [
          _tx(
            id: 't-juin',
            type: 'depense',
            amountCents: 20000,
            categoryId: 'c1',
            date: _ms(2026, 6, 15), // ✓ juin
          ),
          _tx(
            id: 't-juil',
            type: 'depense',
            amountCents: 30000,
            categoryId: 'c1',
            date: _ms(2026, 7, 5), // ✗ juillet
          ),
          _tx(
            id: 't-mai',
            type: 'depense',
            amountCents: 10000,
            categoryId: 'c1',
            date: _ms(2026, 5, 20), // ✗ mai
          ),
        ],
        prev,
      );
      expect(result['c1'], 20000);
    });

    test('transition janvier → décembre de l\'année précédente', () {
      final prev = previousMonth(monthRange(2026, 1)); // = décembre 2025
      final result = computeSpendingTotals(
        [
          _tx(
            id: 't-dec',
            type: 'depense',
            amountCents: 15000,
            categoryId: 'c1',
            date: _ms(2025, 12, 20), // ✓ décembre 2025
          ),
          _tx(
            id: 't-jan',
            type: 'depense',
            amountCents: 25000,
            categoryId: 'c1',
            date: _ms(2026, 1, 5), // ✗ janvier 2026
          ),
        ],
        prev,
      );
      expect(result['c1'], 15000);
    });

    test('cumule plusieurs dépenses de la même catégorie sur le mois précédent',
        () {
      final prev = previousMonth(monthRange(2026, 7));
      final result = computeSpendingTotals(
        [
          _tx(
            id: 't1',
            type: 'depense',
            amountCents: 8000,
            categoryId: 'c1',
            date: _ms(2026, 6, 5),
          ),
          _tx(
            id: 't2',
            type: 'depense',
            amountCents: 12000,
            categoryId: 'c1',
            date: _ms(2026, 6, 20),
          ),
          _tx(
            id: 't3',
            type: 'depense',
            amountCents: 5000,
            categoryId: 'c2',
            date: _ms(2026, 6, 10),
          ),
        ],
        prev,
      );
      expect(result['c1'], 20000); // 8 000 + 12 000
      expect(result['c2'], 5000);
    });

    test('previousMonth sur plage custom utilise le mois du start', () {
      // Plage custom 10-25 juillet → previousMonth = juin 2026
      final customPeriod = DateTimeRange(
        start: DateTime(2026, 7, 10),
        end: DateTime(2026, 7, 25),
      );
      final prev = previousMonth(customPeriod);
      final result = computeSpendingTotals(
        [
          _tx(
            id: 't-juin',
            type: 'depense',
            amountCents: 9000,
            categoryId: 'c1',
            date: _ms(2026, 6, 15),
          ),
        ],
        prev,
      );
      expect(result['c1'], 9000);
    });
  });

}
