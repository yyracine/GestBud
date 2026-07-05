import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../../../shared/data/database/app_database.dart';
import '../../../shared/domain/receipt_line.dart';
import '../../../shared/providers/category_list_provider.dart';
import '../../../shared/providers/transaction_repository_provider.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/category_selector_sheet.dart';
import '../../../shared/widgets/receipt_line_item.dart';

class ScanReviewScreen extends ConsumerStatefulWidget {
  const ScanReviewScreen({super.key, required this.lines});

  final List<ReceiptLine> lines;

  @override
  ConsumerState<ScanReviewScreen> createState() => _ScanReviewScreenState();
}

class _ScanReviewScreenState extends ConsumerState<ScanReviewScreen> {
  late List<ReceiptLine> _lines;
  String? _pendingFocusLineId;
  bool _isValidating = false;
  final _scrollController = ScrollController();

  static const _sheetShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
  );

  @override
  void initState() {
    super.initState();
    _lines = List.of(widget.lines);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  int get _totalCents => _lines.fold(0, (sum, l) => sum + l.amountCents);

  void _updateLabel(int i, String label) {
    setState(() {
      _lines[i] = _lines[i].copyWith(label: label);
    });
  }

  void _updateAmount(int i, int cents) {
    setState(() {
      _lines[i] = _lines[i].copyWith(amountCents: cents);
    });
  }

  void _updateCategory(int i, String categoryName) {
    setState(() {
      _lines[i] = _lines[i].copyWith(category: categoryName);
    });
  }

  void _deleteLine(int i) {
    setState(() {
      _lines.removeAt(i);
    });
  }

  void _addLine() {
    final newLine = ReceiptLine(label: '', amountCents: 0, category: 'Autre');
    setState(() {
      _lines.add(newLine);
      _pendingFocusLineId = newLine.id;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
      if (mounted) setState(() => _pendingFocusLineId = null);
    });
  }

  String? _findCategoryId(String name, List<Category> cats) {
    for (final c in cats) {
      if (c.name == name) return c.id;
    }
    return null;
  }

  Future<void> _validateReceipt() async {
    if (_isValidating || _lines.isEmpty) return;
    setState(() => _isValidating = true);
    try {
      final receiptId = const Uuid().v4();
      await ref
          .read(transactionRepositoryProvider)
          .insertReceiptLines(receiptId, _lines);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reçu enregistré !')),
      );
      context.go('/home');
    } catch (_) {
      if (mounted) setState(() => _isValidating = false);
    }
  }

  Future<void> _showCategorySelector(int index) async {
    final cats = ref.read(categoryListProvider).asData?.value ?? [];
    final currentId = _findCategoryId(_lines[index].category, cats);

    if (!mounted) return;
    final result = await showModalBottomSheet<Category?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: _sheetShape,
      builder: (_) => CategorySelectorSheet(selectedId: currentId),
    );

    if (result != null && mounted) {
      _updateCategory(index, result.name);
    }
  }

  static String _formatCents(int cents) {
    final units = cents ~/ 100;
    final s = units.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final lineCount = _lines.length;
    final totalCents = _totalCents;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text(
          'Revue du reçu',
          style: GoogleFonts.urbanist(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TotalHeaderDelegate(
                    totalCents: totalCents,
                    lineCount: lineCount,
                    formatCents: _formatCents,
                  ),
                ),
                if (_lines.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyListState(),
                  )
                else
                  SliverList.builder(
                    itemCount: _lines.length,
                    itemBuilder: (_, i) {
                      final line = _lines[i];
                      return ReceiptLineItem(
                        key: ValueKey(line.id),
                        line: line,
                        onLabelChanged: (v) => _updateLabel(i, v),
                        onAmountChanged: (v) => _updateAmount(i, v),
                        onCategoryTap: () => _showCategorySelector(i),
                        onDelete: () => _deleteLine(i),
                        autoFocusLabel: line.id == _pendingFocusLineId,
                      );
                    },
                  ),
                SliverToBoxAdapter(
                  child: _AddLineButton(onTap: _addLine),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ],
            ),
          ),
          _ValidateButton(
            enabled: lineCount > 0 && !_isValidating,
            lineCount: lineCount,
            onValidate: _validateReceipt,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sticky header delegate
// ---------------------------------------------------------------------------

class _TotalHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _TotalHeaderDelegate({
    required this.totalCents,
    required this.lineCount,
    required this.formatCents,
  });

  final int totalCents;
  final int lineCount;
  final String Function(int) formatCents;

  @override
  double get minExtent => 56;

  @override
  double get maxExtent => 56;

  @override
  bool shouldRebuild(_TotalHeaderDelegate old) =>
      old.totalCents != totalCents || old.lineCount != lineCount;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppColors.bg,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Text(
        '${formatCents(totalCents)} FCFA · $lineCount article${lineCount > 1 ? 's' : ''}',
        style: GoogleFonts.urbanist(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state (all lines deleted)
// ---------------------------------------------------------------------------

class _EmptyListState extends StatelessWidget {
  const _EmptyListState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              color: AppColors.textSecondary,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Toutes les lignes ont été supprimées.',
              style: GoogleFonts.urbanist(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// "Ajouter une ligne" button
// ---------------------------------------------------------------------------

class _AddLineButton extends StatelessWidget {
  const _AddLineButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: TextButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.add, size: 18, color: AppColors.accent),
        label: Text(
          'Ajouter une ligne',
          style: GoogleFonts.urbanist(
            fontSize: 15,
            color: AppColors.accent,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// "Valider le reçu" button
// ---------------------------------------------------------------------------

class _ValidateButton extends StatelessWidget {
  const _ValidateButton({
    required this.enabled,
    required this.lineCount,
    required this.onValidate,
  });

  final bool enabled;
  final int lineCount;
  final VoidCallback onValidate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        MediaQuery.paddingOf(context).bottom + 16,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton(
          onPressed: enabled ? onValidate : null,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            disabledBackgroundColor: AppColors.accentDim,
            disabledForegroundColor: AppColors.textDisabled,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            enabled
                ? 'Valider le reçu ($lineCount article${lineCount > 1 ? 's' : ''})'
                : 'Valider le reçu',
            style: GoogleFonts.urbanist(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
