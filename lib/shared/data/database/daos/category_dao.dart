import 'package:drift/drift.dart';

import '../app_database.dart';

part 'category_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<AppDatabase> with _$CategoryDaoMixin {
  CategoryDao(super.db);

  Stream<List<Category>> watchAll() => select(categories).watch();

  Future<List<Category>> getAll() => select(categories).get();
}
