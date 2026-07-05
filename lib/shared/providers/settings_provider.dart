import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/app_database.dart';
import 'database_provider.dart';

final settingsProvider = StreamProvider<AppSetting?>((ref) {
  final db = ref.watch(databaseProvider);
  return db.settingsDao.watchSettings();
});

final onboardingShownProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).asData?.value?.onboardingShown ?? false;
});
