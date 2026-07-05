import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../shared/data/database/app_database.dart';
import '../../../shared/providers/transaction_repository_provider.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/utils/category_utils.dart';
import '../../../shared/widgets/category_selector_sheet.dart';

class TransactionDetailScreen extends ConsumerStatefulWidget {
  const TransactionDetailScreen({
    super.key,
    required this.transaction,
    this.category,
  });

  final Transaction transaction;
  final Category? category;

  @override
  ConsumerState<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState
    extends ConsumerState<TransactionDetailScreen> {
  static final _dateFormat = DateFormat('dd/MM/yyyy', 'fr');

  static const _sheetShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
  );

  late String _type;
  late TextEditingController _amountCtrl;
  late Category? _category;
  late DateTime _date;
  late TextEditingController _noteCtrl;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    _type = tx.type;
    _amountCtrl =
        TextEditingController(text: (tx.amountCents ~/ 100).toString());
    _category = widget.category;
    _date = DateTime.fromMillisecondsSinceEpoch(tx.date);
    _noteCtrl = TextEditingController(text: tx.note ?? '');
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

  Future<void> _save() async {
    if (!_canSave || _saving) return;
    setState(() => _saving = true);

    final tx = widget.transaction;
    final amount = int.parse(_amountCtrl.text);

    await ref.read(transactionRepositoryProvider).update(
          Transaction(
            id: tx.id,
            type: _type,
            amountCents: amount * 100,
            currency: tx.currency,
            categoryId: _category!.id,
            receiptId: tx.receiptId,
            note: _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
            date: _date.millisecondsSinceEpoch,
            createdAt: tx.createdAt,
          ),
        );

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Supprimer cette transaction ?',
          style: GoogleFonts.urbanist(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Cette action est définitive.',
          style: GoogleFonts.urbanist(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Annuler',
              style: GoogleFonts.urbanist(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Supprimer',
              style: GoogleFonts.urbanist(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.danger,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(transactionRepositoryProvider).delete(widget.transaction.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _pickCategory() async {
    final picked = await showModalBottomSheet<Category?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: _sheetShape,
      builder: (_) => CategorySelectorSheet(selectedId: _category?.id),
    );
    if (picked != null && mounted) {
      setState(() => _category = picked);
    }
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

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text(
          'Modifier la transaction',
          style: GoogleFonts.urbanist(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          Semantics(
            label: 'Supprimer la transaction',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
              tooltip: 'Supprimer',
              onPressed: _confirmDelete,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.only(bottom: bottomPadding + 24),
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _SegmentedControl(
              value: _type,
              onChanged: (v) => setState(() => _type = v),
            ),
          ),
          const SizedBox(height: 16),
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
          _FormRow(
            onTap: _pickCategory,
            leading: _category != null
                ? _CategoryMiniPastille(category: _category!)
                : null,
            label: _category?.name ?? 'Catégorie',
            labelColor:
                _category != null ? AppColors.textPrimary : AppColors.textSecondary,
          ),
          const Divider(color: AppColors.border, indent: 16, endIndent: 16),
          _FormRow(
            onTap: _pickDate,
            leading: const Icon(
              Icons.calendar_today_outlined,
              color: AppColors.textSecondary,
              size: 20,
            ),
            label: _dateFormat.format(_date),
            labelColor: AppColors.textPrimary,
          ),
          const Divider(color: AppColors.border, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _noteCtrl,
              style: GoogleFonts.urbanist(
                  fontSize: 15, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Note (optionnelle)',
                hintStyle: GoogleFonts.urbanist(
                    fontSize: 15, color: AppColors.textSecondary),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          const Divider(color: AppColors.border, indent: 16, endIndent: 16),
          const SizedBox(height: 24),
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
          ),
          _Segment(
            label: 'Revenu',
            selected: value == 'revenu',
            onTap: () => onChanged('revenu'),
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
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

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
                color:
                    selected ? AppColors.textPrimary : AppColors.textSecondary,
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
                style: GoogleFonts.urbanist(fontSize: 15, color: labelColor),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: 20,
            ),
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
