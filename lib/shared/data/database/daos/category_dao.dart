import 'package:drift/drift.dart';

import '../app_database.dart';

part 'category_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<AppDatabase> with _$CategoryDaoMixin {
  CategoryDao(super.db);

  Stream<List<Category>> watchAll() => select(categories).watch();

  Future<List<Category>> getAll() => select(categories).get();

  Future<void> insertCategory(CategoriesCompanion companion) =>
      into(categories).insert(companion);

  Future<Category?> findByName(String name) =>
      (select(categories)..where((c) => c.name.equals(name))).getSingleOrNull();

  Future<void> updateCategory(
    String id, {
    required String name,
    required String icon,
    required String colorToken,
  }) async {
    await (update(categories)..where((c) => c.id.equals(id))).write(
      CategoriesCompanion(
        name: Value(name),
        icon: Value(icon),
        colorToken: Value(colorToken),
      ),
    );
  }

  Future<int> deleteCategory(String id) =>
      (delete(categories)..where((c) => c.id.equals(id))).go();
}
