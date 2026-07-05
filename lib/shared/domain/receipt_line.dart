import 'package:uuid/uuid.dart';

class ReceiptLine {
  ReceiptLine({
    String? id,
    required this.label,
    required this.amountCents,
    required this.category,
  }) : id = id ?? const Uuid().v4();

  final String id;
  String label;
  int amountCents;
  String category;

  bool get isWarning =>
      amountCents <= 0 || label.trim().isEmpty || category.trim().isEmpty;

  factory ReceiptLine.fromJson(Map<String, dynamic> json) => ReceiptLine(
        label: json['label'] as String? ?? '',
        amountCents: (json['amount_cents'] as num?)?.toInt() ?? 0,
        category: json['category'] as String? ?? 'Autre',
      );

  ReceiptLine copyWith({
    String? label,
    int? amountCents,
    String? category,
  }) =>
      ReceiptLine(
        id: id,
        label: label ?? this.label,
        amountCents: amountCents ?? this.amountCents,
        category: category ?? this.category,
      );
}
