import 'package:flutter_test/flutter_test.dart';
import 'package:gestbud/shared/domain/receipt_line.dart';

void main() {
  group('ReceiptLine.fromJson()', () {
    test('parse les champs standard', () {
      final line = ReceiptLine.fromJson({
        'label': 'Yaourt',
        'amount_cents': 1500,
        'category': 'Alimentation',
      });

      expect(line.label, 'Yaourt');
      expect(line.amountCents, 1500);
      expect(line.category, 'Alimentation');
    });

    test('utilise les valeurs par défaut pour les champs absents', () {
      final line = ReceiptLine.fromJson({});

      expect(line.label, '');
      expect(line.amountCents, 0);
      expect(line.category, 'Autre');
    });

    test('gère amount_cents en double (arrondi vers int)', () {
      final line = ReceiptLine.fromJson({
        'label': 'Article',
        'amount_cents': 1500.9,
        'category': 'Transport',
      });

      expect(line.amountCents, 1500);
    });

    test('assigne un id UUID v4 non-vide', () {
      final line = ReceiptLine.fromJson({'label': 'Test', 'amount_cents': 100, 'category': 'Autre'});
      expect(line.id, isNotEmpty);
      expect(
        line.id,
        matches(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'),
      );
    });
  });

  group('ReceiptLine — unicité des id', () {
    test('deux instances créées séparément ont des id distincts', () {
      final a = ReceiptLine(label: 'A', amountCents: 100, category: 'Autre');
      final b = ReceiptLine(label: 'B', amountCents: 200, category: 'Autre');

      expect(a.id, isNot(equals(b.id)));
    });

    test('id fourni explicitement est conservé', () {
      const customId = '00000000-0000-4000-8000-000000000001';
      final line = ReceiptLine(id: customId, label: 'X', amountCents: 0, category: 'Autre');

      expect(line.id, customId);
    });
  });

  group('ReceiptLine.copyWith()', () {
    test('préserve le même id', () {
      final original = ReceiptLine(label: 'Pain', amountCents: 500, category: 'Alimentation');
      final copy = original.copyWith(label: 'Riz');

      expect(copy.id, original.id);
    });

    test('met à jour uniquement les champs spécifiés', () {
      final original = ReceiptLine(label: 'Pain', amountCents: 500, category: 'Alimentation');
      final copy = original.copyWith(amountCents: 1000);

      expect(copy.label, 'Pain');
      expect(copy.amountCents, 1000);
      expect(copy.category, 'Alimentation');
    });

    test('met à jour label, amountCents et category indépendamment', () {
      final original = ReceiptLine(label: 'A', amountCents: 100, category: 'Autre');

      expect(original.copyWith(label: 'B').label, 'B');
      expect(original.copyWith(amountCents: 999).amountCents, 999);
      expect(original.copyWith(category: 'Transport').category, 'Transport');
    });
  });

  group('ReceiptLine.isWarning', () {
    test('false quand label, montant et catégorie sont valides', () {
      final line = ReceiptLine(label: 'Yaourt', amountCents: 500, category: 'Alimentation');
      expect(line.isWarning, isFalse);
    });

    test('true quand amountCents est 0', () {
      final line = ReceiptLine(label: 'Yaourt', amountCents: 0, category: 'Alimentation');
      expect(line.isWarning, isTrue);
    });

    test('true quand amountCents est négatif', () {
      final line = ReceiptLine(label: 'Yaourt', amountCents: -100, category: 'Alimentation');
      expect(line.isWarning, isTrue);
    });

    test('true quand label est vide', () {
      final line = ReceiptLine(label: '', amountCents: 500, category: 'Alimentation');
      expect(line.isWarning, isTrue);
    });

    test('true quand label ne contient que des espaces', () {
      final line = ReceiptLine(label: '   ', amountCents: 500, category: 'Alimentation');
      expect(line.isWarning, isTrue);
    });

    test('true quand category est vide', () {
      final line = ReceiptLine(label: 'Yaourt', amountCents: 500, category: '');
      expect(line.isWarning, isTrue);
    });

    test('false pour la catégorie Autre (fallback valide)', () {
      final line = ReceiptLine(label: 'Article', amountCents: 200, category: 'Autre');
      expect(line.isWarning, isFalse);
    });

    test('true quand plusieurs conditions sont réunies', () {
      final line = ReceiptLine(label: '', amountCents: 0, category: '');
      expect(line.isWarning, isTrue);
    });
  });
}
