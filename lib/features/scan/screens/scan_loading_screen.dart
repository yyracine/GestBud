import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/data/database/app_database.dart';
import '../../../shared/domain/receipt_line.dart';
import '../../../shared/network/bff_client.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/category_selector_sheet.dart';
import '../../../shared/widgets/transaction_form_sheet.dart';
import 'scan_review_screen.dart';

class ScanLoadingScreen extends ConsumerStatefulWidget {
  const ScanLoadingScreen({
    super.key,
    required this.imageBytes,
    required this.filename,
  });

  final Uint8List imageBytes;
  final String filename;

  @override
  ConsumerState<ScanLoadingScreen> createState() => _ScanLoadingScreenState();
}

enum _LoadState { loading, networkError, timeout }

class _ScanLoadingScreenState extends ConsumerState<ScanLoadingScreen>
    with SingleTickerProviderStateMixin {
  _LoadState _state = _LoadState.loading;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  static const _sheetShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
  );

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.4, end: 0.8).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendToServer());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _sendToServer() async {
    try {
      final result = await ref.read(bffClientProvider).postMultipart(
        '/scan/receipt',
        imageBytes: widget.imageBytes,
        filename: widget.filename,
      );

      final rawLines = result['lines'] as List<dynamic>? ?? [];
      final lines = rawLines
          .map((e) => ReceiptLine.fromJson(e as Map<String, dynamic>))
          .toList();

      if (!mounted) return;
      await Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute(
          builder: (_) => ScanReviewScreen(lines: lines),
        ),
      );
    } on SocketException {
      if (mounted) setState(() => _state = _LoadState.networkError);
    } on TimeoutException {
      if (mounted) setState(() => _state = _LoadState.timeout);
    } catch (_) {
      if (mounted) setState(() => _state = _LoadState.timeout);
    }
  }

  Future<void> _runFormLoop(
    BuildContext context, {
    TransactionFormData? savedData,
  }) async {
    if (!context.mounted) return;

    final result = await showModalBottomSheet<Object?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: _sheetShape,
      builder: (_) => TransactionFormSheet(savedData: savedData),
    );

    if (result is PickCategorySignal && context.mounted) {
      final category = await showModalBottomSheet<Category?>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.surface,
        shape: _sheetShape,
        builder: (_) => CategorySelectorSheet(
          selectedId: result.formData.category?.id,
        ),
      );

      if (context.mounted) {
        await _runFormLoop(
          context,
          savedData: result.formData.copyWith(
            category: category ?? result.formData.category,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text(
          'Analyse en cours…',
          style: GoogleFonts.urbanist(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: switch (_state) {
        _LoadState.networkError =>
          _NetworkErrorState(onManualEntry: () => _runFormLoop(context)),
        _LoadState.timeout =>
          _TimeoutErrorState(onManualEntry: () => _runFormLoop(context)),
        _LoadState.loading =>
          _SkeletonBody(pulseAnim: reduceMotion ? null : _pulseAnim),
      },
    );
  }
}

class _NetworkErrorState extends StatelessWidget {
  const _NetworkErrorState({required this.onManualEntry});

  final VoidCallback onManualEntry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_outlined,
              color: AppColors.textSecondary,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Pas de connexion réseau. Saisis le reçu manuellement.',
              style: GoogleFonts.urbanist(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: onManualEntry,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Saisie manuelle',
                  style: GoogleFonts.urbanist(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeoutErrorState extends StatelessWidget {
  const _TimeoutErrorState({required this.onManualEntry});

  final VoidCallback onManualEntry;

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
              'Impossible de lire le reçu. Saisis-le manuellement.',
              style: GoogleFonts.urbanist(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: onManualEntry,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Saisie manuelle',
                  style: GoogleFonts.urbanist(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBody extends StatelessWidget {
  const _SkeletonBody({this.pulseAnim});

  final Animation<double>? pulseAnim;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 8),
      children: [
        _SkeletonLine(widthFactor: 0.55, pulseAnim: pulseAnim),
        _SkeletonLine(widthFactor: 0.40, pulseAnim: pulseAnim),
        _SkeletonLine(widthFactor: 0.65, pulseAnim: pulseAnim),
        _SkeletonLine(widthFactor: 0.35, pulseAnim: pulseAnim),
        _SkeletonLine(widthFactor: 0.50, pulseAnim: pulseAnim),
        _SkeletonLine(widthFactor: 0.45, pulseAnim: pulseAnim),
      ],
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.widthFactor, this.pulseAnim});

  final double widthFactor;
  final Animation<double>? pulseAnim;

  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.surfaceRaised,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: widthFactor,
                  child: Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceRaised,
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 56,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceRaised,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 52,
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(7),
            ),
          ),
        ],
      ),
    );

    if (pulseAnim == null) {
      return Opacity(opacity: 0.6, child: child);
    }

    return AnimatedBuilder(
      animation: pulseAnim!,
      builder: (_, inner) => Opacity(opacity: pulseAnim!.value, child: inner),
      child: child,
    );
  }
}
