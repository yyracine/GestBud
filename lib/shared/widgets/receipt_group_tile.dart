import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/database/app_database.dart';
import '../theme/app_colors.dart';
import 'transaction_tile.dart';

class ReceiptGroupTile extends StatefulWidget {
  const ReceiptGroupTile({
    super.key,
    required this.transactions,
    required this.categoryMap,
    required this.onLineTap,
  });

  final List<Transaction> transactions;
  final Map<String, Category> categoryMap;
  final void Function(Transaction) onLineTap;

  @override
  State<ReceiptGroupTile> createState() => _ReceiptGroupTileState();
}

class _ReceiptGroupTileState extends State<ReceiptGroupTile> {
  bool _expanded = false;

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
    final n = widget.transactions.length;
    final total = widget.transactions.fold(0, (sum, t) => sum + t.amountCents);
    final label =
        'Reçu · $n article${n > 1 ? "s" : ""} · ${_formatCents(total)} FCFA';
    final stateLabel = _expanded ? 'développé' : 'réduit';

    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final animDuration =
        reduceMotion ? Duration.zero : const Duration(milliseconds: 200);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: 'Reçu, $n article${n > 1 ? "s" : ""}, $stateLabel',
          button: true,
          excludeSemantics: true,
          child: InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 60),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceRaised,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.receipt_long_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: GoogleFonts.urbanist(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0.0,
                      duration: animDuration,
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const Divider(color: AppColors.border, height: 1),
        AnimatedSize(
          duration: animDuration,
          curve: Curves.easeInOut,
          child: _expanded
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: widget.transactions
                      .map(
                        (tx) => TransactionTile(
                          transaction: tx,
                          category: widget.categoryMap[tx.categoryId],
                          onTap: () => widget.onLineTap(tx),
                        ),
                      )
                      .toList(),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
