import 'package:drift/drift.dart';

import '../app_database.dart';

part 'settings_dao.g.dart';

@DriftAccessor(tables: [AppSettings])
class SettingsDao extends DatabaseAccessor<AppDatabase> with _$SettingsDaoMixin {
  SettingsDao(super.db);

  Stream<AppSetting?> watchSettings() =>
      select(appSettings).watchSingleOrNull();

  Future<AppSetting?> getSettings() => select(appSettings).getSingleOrNull();

  Future<int> upsert(AppSettingsCompanion row) =>
      into(appSettings).insertOnConflictUpdate(row);

  Future<void> setOnboardingShown(bool value) => upsert(
        AppSettingsCompanion(
          id: const Value('default'),
          onboardingShown: Value(value),
        ),
      );
}
