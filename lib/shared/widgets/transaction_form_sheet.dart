import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../data/database/app_database.dart';
import '../providers/transaction_repository_provider.dart';
import '../theme/app_colors.dart';
import '../utils/category_utils.dart';

/// Données du formulaire transaction — préservées lors du changement de catégorie.
class TransactionFormData {
  final String type;
  final String amountText;
  final Category? category;
  final DateTime date;
  final String note;

  TransactionFormData({
    this.type = 'depense',
    this.amountText = '',
    this.category,
    DateTime? date,
    this.note = '',
  }) : date = date ?? DateTime.now();

  TransactionFormData copyWith({
    String? type,
    String? amountText,
    Object? category = _sentinel,
    DateTime? date,
    String? note,
  }) {
    return TransactionFormData(
      type: type ?? this.type,
      amountText: amountText ?? this.amountText,
      category: category == _sentinel ? this.category : category as Category?,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }

  static const Object _sentinel = Object();
}

/// Signal renvoyé quand l'utilisateur demande l'ouverture du sélecteur de catégorie.
class PickCategorySignal {
  final TransactionFormData formData;
  const PickCategorySignal(this.formData);
}

class TransactionFormSheet extends ConsumerStatefulWidget {
  const TransactionFormSheet({super.key, this.savedData});

  final TransactionFormData? savedData;

  @override
  ConsumerState<TransactionFormSheet> createState() => _TransactionFormSheetState();
}

class _TransactionFormSheetState extends ConsumerState<TransactionFormSheet> {
  static final _dateFormat = DateFormat('dd/MM/yyyy', 'fr');

  late String _type;
  late TextEditingController _amountCtrl;
  late Category? _category;
  late DateTime _date;
  late TextEditingController _noteCtrl;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final d = widget.savedData;
    _type = d?.type ?? 'depense';
    _amountCtrl = TextEditingController(text: d?.amountText ?? '');
    _category = d?.category;
    _date = d?.date ?? DateTime.now();
    _noteCtrl = TextEditingController(text: d?.note ?? '');
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  bool get _canSave {
    final amount = int.tryParse(_amountCtrl.text);
    return amount != null && amount > 0 && _category != null;
  }

  TransactionFormData get _currentData => TransactionFormData(
        type: _type,
        amountText: _amountCtrl.text,
        category: _category,
        date: _date,
        note: _noteCtrl.text,
      );

  Future<void> _save() async {
    if (!_canSave || _saving) return;
    setState(() => _saving = true);

    final amount = int.parse(_amountCtrl.text);
    await ref.read(transactionRepositoryProvider).insert(
          type: _type,
          amountCents: amount * 100,
          categoryId: _category!.id,
          date: _date.millisecondsSinceEpoch,
          note: _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
        );

    if (mounted) Navigator.of(context).pop();
  }

  void _pickCategory() {
    Navigator.of(context).pop(PickCategorySignal(_currentData));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('fr'),
    );
    if (picked != null && mounted) {
      setState(() => _date = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Nouvelle transaction',
            style: GoogleFonts.urbanist(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          // Segmented control Dépense / Revenu
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _SegmentedControl(
              value: _type,
              onChanged: (v) => setState(() => _type = v),
            ),
          ),
          const SizedBox(height: 24),
          // Montant
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              style: GoogleFonts.urbanist(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: GoogleFonts.urbanist(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDisabled,
                ),
                suffix: Text(
                  'FCFA',
                  style: GoogleFonts.urbanist(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const Divider(color: AppColors.border, indent: 16, endIndent: 16),
          // Catégorie
          _FormRow(
            onTap: _pickCategory,
            leading: _category != null
                ? _CategoryMiniPastille(category: _category!)
                : null,
            label: _category?.name ?? 'Catégorie',
            labelColor: _category != null ? AppColors.textPrimary : AppColors.textSecondary,
          ),
          const Divider(color: AppColors.border, indent: 16, endIndent: 16),
          // Date
          _FormRow(
            onTap: _pickDate,
            leading: const Icon(Icons.calendar_today_outlined, color: AppColors.textSecondary, size: 20),
            label: _dateFormat.format(_date),
            labelColor: AppColors.textPrimary,
          ),
          const Divider(color: AppColors.border, indent: 16, endIndent: 16),
          // Note
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _noteCtrl,
              style: GoogleFonts.urbanist(fontSize: 15, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Note (optionnelle)',
                hintStyle: GoogleFonts.urbanist(fontSize: 15, color: AppColors.textSecondary),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          const Divider(color: AppColors.border, indent: 16, endIndent: 16),
          const SizedBox(height: 16),
          // CTA
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _canSave && !_saving ? _save : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  disabledBackgroundColor: AppColors.accentDim,
                  foregroundColor: AppColors.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textPrimary,
                        ),
                      )
                    : Text(
                        'Enregistrer',
                        style: GoogleFonts.urbanist(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SegmentedControl extends StatelessWidget {
  const _SegmentedControl({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _Segment(
            label: 'Dépense',
            selected: value == 'depense',
            onTap: () => onChanged('depense'),
            isFirst: true,
          ),
          _Segment(
            label: 'Revenu',
            selected: value == 'revenu',
            onTap: () => onChanged('revenu'),
            isFirst: false,
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.isFirst,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Semantics(
          label: '$label${selected ? ", sélectionné" : ""}',
          selected: selected,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: selected ? AppColors.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: GoogleFonts.urbanist(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FormRow extends StatelessWidget {
  const _FormRow({
    required this.onTap,
    required this.label,
    required this.labelColor,
    this.leading,
  });

  final VoidCallback onTap;
  final String label;
  final Color labelColor;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.urbanist(
                  fontSize: 15,
                  color: labelColor,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _CategoryMiniPastille extends StatelessWidget {
  const _CategoryMiniPastille({required this.category});

  final Category category;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = CategoryUtils.pastilleColors(category.colorToken);
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(CategoryUtils.iconData(category.icon), color: fg, size: 16),
    );
  }
}
