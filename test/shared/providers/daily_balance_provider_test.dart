import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestbud/shared/data/database/app_database.dart';
import 'package:gestbud/shared/providers/daily_balance_provider.dart';
import 'package:gestbud/shared/providers/selected_period_provider.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Transaction _tx({
  required String id,
  required String type,
  required int amountCents,
  required int date,
  String categoryId = 'cat1',
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

final _july2026 = monthRange(2026, 7); // 1er–31 juillet 2026

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('computeDailyBalances()', () {
    test('liste vide de tx → tous les points à 0', () {
      final points = computeDailyBalances([], _july2026);
      expect(points.length, 31); // juillet = 31 jours
      expect(points.every((p) => p.balanceCents == 0), isTrue);
    });

    test('un point par jour de la période', () {
      final single = DateTimeRange(
        start: DateTime(2026, 7, 1),
        end: DateTime(2026, 7, 1),
      );
      final points = computeDailyBalances([], single);
      expect(points.length, 1);
    });

    test('période 5 jours → 5 points', () {
      final range = DateTimeRange(
        start: DateTime(2026, 7, 10),
        end: DateTime(2026, 7, 14),
      );
      final points = computeDailyBalances([], range);
      expect(points.length, 5);
      expect(points.first.date, DateTime(2026, 7, 10));
      expect(points.last.date, DateTime(2026, 7, 14));
    });

    test('tx pré-période → solde initial pour tous les jours de la période', () {
      // Un revenu en juin → solde initial = +200 FCFA (20000 centimes)
      final tx = _tx(
        id: 't1',
        type: 'revenu',
        amountCents: 20000,
        date: _ms(2026, 6, 15),
      );
      final points = computeDailyBalances([tx], _july2026);
      expect(points.length, 31);
      expect(points.first.balanceCents, 20000);
      expect(points.last.balanceCents, 20000); // aucune tx en juillet → carry-forward
    });

    test('dépense pré-période → solde initial négatif (AC-3)', () {
      final tx = _tx(
        id: 't1',
        type: 'depense',
        amountCents: 50000,
        date: _ms(2026, 6, 10),
      );
      final points = computeDailyBalances([tx], _july2026);
      expect(points.first.balanceCents, -50000);
    });

    test('tx dans la période → solde mis à jour le bon jour', () {
      final tx = _tx(
        id: 't1',
        type: 'revenu',
        amountCents: 10000,
        date: _ms(2026, 7, 5),
      );
      final points = computeDailyBalances([tx], _july2026);
      // Jours 1–4 : 0
      for (var i = 0; i < 4; i++) {
        expect(points[i].balanceCents, 0, reason: 'jour ${i + 1}');
      }
      // Jour 5 : +10 000
      expect(points[4].balanceCents, 10000);
      // Jours suivants : carry-forward
      expect(points[5].balanceCents, 10000);
      expect(points[30].balanceCents, 10000);
    });

    test('carry-forward : jour sans tx = solde du jour précédent (AC-2)', () {
      final tx = _tx(
        id: 't1',
        type: 'depense',
        amountCents: 8000,
        date: _ms(2026, 7, 10),
      );
      final points = computeDailyBalances([tx], _july2026);
      expect(points[9].balanceCents, -8000); // jour 10
      expect(points[10].balanceCents, -8000); // jour 11 — carry-forward
      expect(points[20].balanceCents, -8000); // jour 21 — carry-forward
    });

    test('revenus ajoutent, dépenses soustraient', () {
      final txs = [
        _tx(id: 't1', type: 'revenu', amountCents: 100000, date: _ms(2026, 7, 1)),
        _tx(id: 't2', type: 'depense', amountCents: 30000, date: _ms(2026, 7, 2)),
        _tx(id: 't3', type: 'revenu', amountCents: 20000, date: _ms(2026, 7, 2)),
      ];
      final points = computeDailyBalances(txs, _july2026);
      expect(points[0].balanceCents, 100000); // après jour 1
      expect(points[1].balanceCents, 90000);  // +100k −30k +20k = 90k
    });

    test('plusieurs tx le même jour : cumulées dans le point du jour', () {
      final txs = [
        _tx(id: 't1', type: 'depense', amountCents: 5000, date: _ms(2026, 7, 15, 9)),
        _tx(id: 't2', type: 'depense', amountCents: 3000, date: _ms(2026, 7, 15, 14)),
        _tx(id: 't3', type: 'depense', amountCents: 2000, date: _ms(2026, 7, 15, 19)),
      ];
      final points = computeDailyBalances(txs, _july2026);
      expect(points[14].balanceCents, -10000); // −5k −3k −2k = −10k
    });

    test('solde négatif visible sous zéro (AC-3)', () {
      final tx = _tx(
        id: 't1',
        type: 'depense',
        amountCents: 200000,
        date: _ms(2026, 7, 5),
      );
      final points = computeDailyBalances([tx], _july2026);
      expect(points[4].balanceCents, isNegative);
    });

    test('tx le dernier jour à 23:59:59 incluse dans le dernier point', () {
      final endMs = DateTime(2026, 7, 31, 23, 59, 59).millisecondsSinceEpoch;
      final tx = _tx(id: 't1', type: 'revenu', amountCents: 15000, date: endMs);
      final points = computeDailyBalances([tx], _july2026);
      expect(points.last.balanceCents, 15000);
    });

    test('tx le premier jour à minuit incluse dans le premier point (boundary)', () {
      final startMs = _july2026.start.millisecondsSinceEpoch; // 1er juil 00h00
      final tx = _tx(id: 't1', type: 'revenu', amountCents: 6000, date: startMs);
      final points = computeDailyBalances([tx], _july2026);
      expect(points.first.balanceCents, 6000);
    });
  });
}
