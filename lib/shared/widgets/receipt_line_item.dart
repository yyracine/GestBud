import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../domain/receipt_line.dart';
import '../theme/app_colors.dart';
import '../utils/category_utils.dart';

class ReceiptLineItem extends StatefulWidget {
  const ReceiptLineItem({
    required super.key,
    required this.line,
    required this.onLabelChanged,
    required this.onAmountChanged,
    required this.onCategoryTap,
    required this.onDelete,
    this.autoFocusLabel = false,
  });

  final ReceiptLine line;
  final ValueChanged<String> onLabelChanged;
  final ValueChanged<int> onAmountChanged;
  final VoidCallback onCategoryTap;
  final VoidCallback onDelete;
  final bool autoFocusLabel;

  @override
  State<ReceiptLineItem> createState() => _ReceiptLineItemState();
}

class _ReceiptLineItemState extends State<ReceiptLineItem> {
  late TextEditingController _labelCtrl;
  late TextEditingController _amountCtrl;
  late FocusNode _labelFocus;

  @override
  void initState() {
    super.initState();
    _labelCtrl = TextEditingController(text: widget.line.label);
    _amountCtrl = TextEditingController(
      text: widget.line.amountCents > 0
          ? (widget.line.amountCents ~/ 100).toString()
          : '',
    );
    _labelFocus = FocusNode();

    _labelCtrl.addListener(() => widget.onLabelChanged(_labelCtrl.text));
    _amountCtrl.addListener(() {
      final val = int.tryParse(_amountCtrl.text) ?? 0;
      widget.onAmountChanged(val * 100);
    });

    if (widget.autoFocusLabel) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) FocusScope.of(context).requestFocus(_labelFocus);
      });
    }
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _amountCtrl.dispose();
    _labelFocus.dispose();
    super.dispose();
  }

  bool get _isWarning => widget.line.isWarning;

  @override
  Widget build(BuildContext context) {
    final (iconName, colorToken) = CategoryUtils.categoryVisuals(widget.line.category);
    final (catBg, catFg) = CategoryUtils.pastilleColors(colorToken);
    final iconData = CategoryUtils.iconData(iconName);

    return Semantics(
      label:
          '${widget.line.category}, ${widget.line.label}, ${widget.line.amountCents ~/ 100} francs CFA',
      customSemanticsActions: {
        CustomSemanticsAction(label: 'Supprimer'): widget.onDelete,
      },
      child: Dismissible(
        key: ValueKey(widget.line.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => widget.onDelete(),
        background: Container(
          color: AppColors.danger,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.delete_outline, color: AppColors.textPrimary),
        ),
        child: Container(
          constraints: const BoxConstraints(minHeight: 60),
          decoration: BoxDecoration(
            color: _isWarning ? const Color(0xFF3A2A00) : Colors.transparent,
            border: Border(
              left: _isWarning
                  ? const BorderSide(color: AppColors.warning, width: 3)
                  : BorderSide.none,
              bottom: const BorderSide(color: AppColors.border),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(width: 12),
              // Category badge
              GestureDetector(
                onTap: widget.onCategoryTap,
                child: Semantics(
                  label: widget.line.category,
                  button: true,
                  excludeSemantics: true,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: catBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(iconData, color: catFg, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Label field
              Expanded(
                child: TextField(
                  controller: _labelCtrl,
                  focusNode: _labelFocus,
                  style: GoogleFonts.urbanist(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Libellé',
                    hintStyle: GoogleFonts.urbanist(
                      fontSize: 15,
                      color: AppColors.textDisabled,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Amount field
              SizedBox(
                width: 100,
                child: TextField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.right,
                  style: GoogleFonts.urbanist(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: GoogleFonts.urbanist(
                      fontSize: 15,
                      color: AppColors.textDisabled,
                    ),
                    suffixText: 'F',
                    suffixStyle: GoogleFonts.urbanist(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    isDense: true,
                  ),
                ),
              ),
              // Warning icon
              if (_isWarning)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.warning,
                    size: 18,
                  ),
                ),
              // Menu ⋯
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_horiz,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                color: AppColors.surfaceRaised,
                padding: EdgeInsets.zero,
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Supprimer',
                      style: GoogleFonts.urbanist(
                        fontSize: 15,
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                ],
                onSelected: (_) => widget.onDelete(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
