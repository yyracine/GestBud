import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Période actuellement sélectionnée dans le Tableau de bord.
/// Défaut : mois calendaire courant (1er → dernier jour).
final selectedPeriodProvider =
    NotifierProvider<SelectedPeriodNotifier, DateTimeRange>(
  SelectedPeriodNotifier.new,
);

class SelectedPeriodNotifier extends Notifier<DateTimeRange> {
  @override
  DateTimeRange build() {
    final now = DateTime.now();
    return monthRange(now.year, now.month);
  }

  void selectRange(DateTimeRange range) {
    state = range;
  }
}

/// Retourne un [DateTimeRange] couvrant le mois calendaire complet.
/// Le dernier jour est calculé via `DateTime(year, month+1, 0)`.
DateTimeRange monthRange(int year, int month) {
  final start = DateTime(year, month, 1);
  final end = DateTime(year, month + 1, 0);
  return DateTimeRange(start: start, end: end);
}

/// Retourne `true` si [range] couvre exactement un mois calendaire complet.
bool isFullMonth(DateTimeRange range) {
  final s = range.start;
  final e = range.end;
  if (s.day != 1) return false;
  final lastDay = DateTime(s.year, s.month + 1, 0).day;
  return e.year == s.year && e.month == s.month && e.day == lastDay;
}

/// Retourne le [DateTimeRange] du mois précédant le début de [period].
DateTimeRange previousMonth(DateTimeRange period) {
  final s = period.start;
  if (s.month == 1) return monthRange(s.year - 1, 12);
  return monthRange(s.year, s.month - 1);
}

/// Retourne le [DateTimeRange] du mois suivant le début de [period].
DateTimeRange nextMonth(DateTimeRange period) {
  final s = period.start;
  if (s.month == 12) return monthRange(s.year + 1, 1);
  return monthRange(s.year, s.month + 1);
}
