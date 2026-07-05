import 'package:flutter_test/flutter_test.dart';
import 'package:gestbud/features/categories/screens/category_management_screen.dart';
import 'package:gestbud/shared/data/database/app_database.dart';

Category _cat({
  required String id,
  required String name,
  required bool isPredefined,
  int createdAt = 0,
}) => Category(
  id: id,
  name: name,
  isPredefined: isPredefined,
  icon: 'more_horiz',
  colorToken: 'text-secondary',
  createdAt: createdAt,
);

void main() {
  group('sortCategories', () {
    test('empty list returns empty', () {
      expect(sortCategories([]), isEmpty);
    });

    test('predefined before custom regardless of input order', () {
      final custom = _cat(id: 'c1', name: 'Custom', isPredefined: false, createdAt: 1);
      final pred = _cat(id: 'p1', name: 'Predefined', isPredefined: true, createdAt: 2);
      final result = sortCategories([custom, pred]);
      expect(result[0].id, 'p1');
      expect(result[1].id, 'c1');
    });

    test('only predefined — all returned', () {
      final p1 = _cat(id: 'p1', name: 'A', isPredefined: true, createdAt: 10);
      final p2 = _cat(id: 'p2', name: 'B', isPredefined: true, createdAt: 20);
      final result = sortCategories([p2, p1]);
      expect(result, hasLength(2));
      expect(result.every((c) => c.isPredefined), isTrue);
    });

    test('custom sorted by createdAt ascending (oldest first)', () {
      final c1 = _cat(id: 'c1', name: 'Newer', isPredefined: false, createdAt: 2000);
      final c2 = _cat(id: 'c2', name: 'Older', isPredefined: false, createdAt: 1000);
      final result = sortCategories([c1, c2]);
      expect(result[0].id, 'c2');
      expect(result[1].id, 'c1');
    });

    test('mixed list — predefined section intact, custom section sorted', () {
      final p1 = _cat(id: 'p1', name: 'P1', isPredefined: true);
      final p2 = _cat(id: 'p2', name: 'P2', isPredefined: true);
      final c1 = _cat(id: 'c1', name: 'C1', isPredefined: false, createdAt: 100);
      final c2 = _cat(id: 'c2', name: 'C2', isPredefined: false, createdAt: 200);
      final result = sortCategories([c2, p1, c1, p2]);
      expect(result[0].isPredefined, isTrue);
      expect(result[1].isPredefined, isTrue);
      expect(result[2].id, 'c1');
      expect(result[3].id, 'c2');
    });

    test('only custom — sorted by createdAt', () {
      final c1 = _cat(id: 'c1', name: 'A', isPredefined: false, createdAt: 300);
      final c2 = _cat(id: 'c2', name: 'B', isPredefined: false, createdAt: 100);
      final c3 = _cat(id: 'c3', name: 'C', isPredefined: false, createdAt: 200);
      final result = sortCategories([c1, c2, c3]);
      expect(result[0].id, 'c2');
      expect(result[1].id, 'c3');
      expect(result[2].id, 'c1');
    });
  });
}
