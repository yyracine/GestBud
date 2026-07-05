import 'package:flutter_test/flutter_test.dart';
import 'package:gestbud/features/categories/widgets/category_form_sheet.dart';
import 'package:gestbud/shared/data/database/app_database.dart';

Category _cat({
  required String id,
  required String name,
  bool isPredefined = false,
}) =>
    Category(
      id: id,
      name: name,
      isPredefined: isPredefined,
      icon: 'star',
      colorToken: 'cat-custom-rose',
      createdAt: 0,
    );

void main() {
  group('isDuplicate', () {
    test('retourne false pour liste vide', () {
      expect(isDuplicate('Test', []), isFalse);
    });

    test('retourne true si nom identique (même casse)', () {
      expect(
        isDuplicate('Alimentation', [_cat(id: '1', name: 'Alimentation')]),
        isTrue,
      );
    });

    test('insensible à la casse — entrée en majuscules', () {
      expect(
        isDuplicate('ALIMENTATION', [_cat(id: '1', name: 'Alimentation')]),
        isTrue,
      );
    });

    test('insensible à la casse — entrée en minuscules', () {
      expect(
        isDuplicate('alimentation', [_cat(id: '1', name: 'Alimentation')]),
        isTrue,
      );
    });

    test('retourne false si nom différent', () {
      expect(
        isDuplicate('Voyage', [_cat(id: '1', name: 'Alimentation')]),
        isFalse,
      );
    });

    test('trim les espaces avant comparaison', () {
      expect(
        isDuplicate('  Alimentation  ', [_cat(id: '1', name: 'Alimentation')]),
        isTrue,
      );
    });

    test('catégorie prédéfinie compte comme doublon', () {
      expect(
        isDuplicate('Transport', [
          _cat(id: '1', name: 'Alimentation'),
          _cat(id: '2', name: 'Transport', isPredefined: true),
        ]),
        isTrue,
      );
    });

    group('excludeId (mode édition)', () {
      test('retourne false si le seul match est la catégorie exclue (self-edit)', () {
        expect(
          isDuplicate(
            'Alimentation',
            [_cat(id: '1', name: 'Alimentation')],
            excludeId: '1',
          ),
          isFalse,
        );
      });

      test('retourne false si le seul match est exclu, insensible à la casse', () {
        expect(
          isDuplicate(
            'ALIMENTATION',
            [_cat(id: '1', name: 'Alimentation')],
            excludeId: '1',
          ),
          isFalse,
        );
      });

      test('retourne true si une autre catégorie (non exclue) correspond', () {
        expect(
          isDuplicate(
            'Transport',
            [
              _cat(id: '1', name: 'Alimentation'),
              _cat(id: '2', name: 'Transport'),
            ],
            excludeId: '1',
          ),
          isTrue,
        );
      });
    });
  });
}
