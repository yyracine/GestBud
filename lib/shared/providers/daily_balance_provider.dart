import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/app_database.dart';
import 'selected_period_provider.dart';
import 'transaction_list_provider.dart';

class DailyBalancePoint {
  const DailyBalancePoint({required this.date, required this.balanceCents});
  final DateTime date;
  final int balanceCents;
}

final dailyBalanceProvider = Provider<List<DailyBalancePoint>>((ref) {
  final period = ref.watch(selectedPeriodProvider);
  final allTx = ref.watch(transactionListProvider).asData?.value ?? <Transaction>[];
  return computeDailyBalances(allTx, period);
});

List<DailyBalancePoint> computeDailyBalances(
  List<Transaction> transactions,
  DateTimeRange period,
) {
  final startMs = period.start.millisecondsSinceEpoch;

  // Solde initial : toutes les transactions strictement avant le début de période
  int running = 0;
  for (final t in transactions) {
    if (t.date < startMs) {
      running += t.type == 'revenu' ? t.amountCents : -t.amountCents;
    }
  }

  // Un point par jour de la période (carry-forward si aucune tx ce jour)
  final days = period.end.difference(period.start).inDays + 1;
  final points = <DailyBalancePoint>[];

  for (var i = 0; i < days; i++) {
    final day = DateTime(
      period.start.year,
      period.start.month,
      period.start.day + i,
    );
    final dayStartMs = day.millisecondsSinceEpoch;
    final dayEndMs =
        DateTime(day.year, day.month, day.day, 23, 59, 59).millisecondsSinceEpoch;

    for (final t in transactions) {
      if (t.date >= dayStartMs && t.date <= dayEndMs) {
        running += t.type == 'revenu' ? t.amountCents : -t.amountCents;
      }
    }

    points.add(DailyBalancePoint(date: day, balanceCents: running));
  }

  return points;
}
