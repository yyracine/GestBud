import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/app_database.dart';
import 'database_provider.dart';

// SEUL StreamProvider sur CategoryDao.watchAll() — AD-11
final categoryListProvider = StreamProvider<List<Category>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.categoryDao.watchAll();
});
