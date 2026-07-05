import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestbud/shared/providers/selected_period_provider.dart';

void main() {
  group('monthRange()', () {
    test('start = 1er du mois, end = dernier jour du mois', () {
      final r = monthRange(2026, 7);
      expect(r.start, DateTime(2026, 7, 1));
      expect(r.end, DateTime(2026, 7, 31));
    });

    test('mois de 28 jours (février année commune)', () {
      final r = monthRange(2026, 2);
      expect(r.start, DateTime(2026, 2, 1));
      expect(r.end, DateTime(2026, 2, 28));
    });

    test('mois de 29 jours (février bissextile)', () {
      final r = monthRange(2024, 2);
      expect(r.end, DateTime(2024, 2, 29));
    });

    test('mois de 30 jours (avril)', () {
      final r = monthRange(2026, 4);
      expect(r.end, DateTime(2026, 4, 30));
    });

    test('décembre : end = 31 décembre', () {
      final r = monthRange(2026, 12);
      expect(r.start, DateTime(2026, 12, 1));
      expect(r.end, DateTime(2026, 12, 31));
    });

    test('janvier : end = 31 janvier', () {
      final r = monthRange(2026, 1);
      expect(r.end, DateTime(2026, 1, 31));
    });
  });

  group('isFullMonth()', () {
    test('mois complet → true', () {
      expect(isFullMonth(monthRange(2026, 7)), isTrue);
    });

    test('plage custom (pas le 1er) → false', () {
      final r = DateTimeRange(
        start: DateTime(2026, 7, 5),
        end: DateTime(2026, 7, 31),
      );
      expect(isFullMonth(r), isFalse);
    });

    test('plage custom (fin pas dernier jour) → false', () {
      final r = DateTimeRange(
        start: DateTime(2026, 7, 1),
        end: DateTime(2026, 7, 15),
      );
      expect(isFullMonth(r), isFalse);
    });

    test('plage sur deux mois → false', () {
      final r = DateTimeRange(
        start: DateTime(2026, 6, 1),
        end: DateTime(2026, 7, 31),
      );
      expect(isFullMonth(r), isFalse);
    });

    test('mois de février bissextile complet → true', () {
      expect(isFullMonth(monthRange(2024, 2)), isTrue);
    });
  });

  group('previousMonth()', () {
    test('mois normal → mois précédent', () {
      final current = monthRange(2026, 7);
      final prev = previousMonth(current);
      expect(prev.start, DateTime(2026, 6, 1));
      expect(prev.end, DateTime(2026, 6, 30));
    });

    test('janvier → décembre de l\'année précédente', () {
      final current = monthRange(2026, 1);
      final prev = previousMonth(current);
      expect(prev.start, DateTime(2025, 12, 1));
      expect(prev.end, DateTime(2025, 12, 31));
    });

    test('retourne toujours un mois complet', () {
      final prev = previousMonth(monthRange(2026, 3));
      expect(isFullMonth(prev), isTrue);
    });

    test('fonctionne sur une plage custom (utilise le mois du start)', () {
      final custom = DateTimeRange(
        start: DateTime(2026, 7, 10),
        end: DateTime(2026, 7, 20),
      );
      final prev = previousMonth(custom);
      expect(prev.start, DateTime(2026, 6, 1));
    });
  });

  group('nextMonth()', () {
    test('mois normal → mois suivant', () {
      final current = monthRange(2026, 7);
      final next = nextMonth(current);
      expect(next.start, DateTime(2026, 8, 1));
      expect(next.end, DateTime(2026, 8, 31));
    });

    test('décembre → janvier de l\'année suivante', () {
      final current = monthRange(2026, 12);
      final next = nextMonth(current);
      expect(next.start, DateTime(2027, 1, 1));
      expect(next.end, DateTime(2027, 1, 31));
    });

    test('retourne toujours un mois complet', () {
      final next = nextMonth(monthRange(2026, 3));
      expect(isFullMonth(next), isTrue);
    });
  });

  group('selectedPeriodProvider', () {
    test('initialise au mois courant', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final period = container.read(selectedPeriodProvider);
      final now = DateTime.now();
      final expected = monthRange(now.year, now.month);

      expect(period.start, expected.start);
      expect(period.end, expected.end);
    });

    test('peut etre mis a jour vers le mois precedent', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initial = container.read(selectedPeriodProvider);
      final prev = previousMonth(initial);
      container.read(selectedPeriodProvider.notifier).selectRange(prev);

      expect(container.read(selectedPeriodProvider), prev);
    });

    test('peut etre mis a jour vers une plage custom', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final custom = DateTimeRange(
        start: DateTime(2026, 6, 1),
        end: DateTime(2026, 6, 15),
      );
      container.read(selectedPeriodProvider.notifier).selectRange(custom);

      expect(container.read(selectedPeriodProvider), custom);
      expect(isFullMonth(container.read(selectedPeriodProvider)), isFalse);
    });
  });
}
