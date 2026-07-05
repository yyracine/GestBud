import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../shared/theme/app_colors.dart';
import 'scan_loading_screen.dart';

class ScanEntryScreen extends StatefulWidget {
  const ScanEntryScreen({super.key});

  @override
  State<ScanEntryScreen> createState() => _ScanEntryScreenState();
}

enum _ScanState { idle, picking, permissionDenied }

class _ScanEntryScreenState extends State<ScanEntryScreen> {
  _ScanState _state = _ScanState.idle;

  Future<void> _pickFromCamera() async {
    if (_state == _ScanState.picking) return;

    final status = await Permission.camera.status;
    if (status.isPermanentlyDenied) {
      if (mounted) setState(() => _state = _ScanState.permissionDenied);
      return;
    }

    if (!status.isGranted) {
      final result = await Permission.camera.request();
      if (result.isPermanentlyDenied) {
        if (mounted) setState(() => _state = _ScanState.permissionDenied);
        return;
      }
      if (!result.isGranted) return;
    }

    await _pickImage(ImageSource.camera);
  }

  Future<void> _pickFromGallery() async {
    if (_state == _ScanState.picking) return;
    await _pickImage(ImageSource.gallery);
  }

  Future<void> _pickImage(ImageSource source) async {
    if (mounted) setState(() => _state = _ScanState.picking);

    try {
      final file = await ImagePicker().pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 2048,
      );

      if (!mounted) return;

      if (file == null) {
        if (source == ImageSource.camera) {
          final status = await Permission.camera.status;
          if (status.isPermanentlyDenied) {
            setState(() => _state = _ScanState.permissionDenied);
            return;
          }
        }
        setState(() => _state = _ScanState.idle);
        return;
      }

      final imageBytes = await file.readAsBytes();
      if (!mounted) return;

      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => ScanLoadingScreen(
            imageBytes: imageBytes,
            filename: file.name,
          ),
        ),
      );

      if (mounted) setState(() => _state = _ScanState.idle);
    } catch (_) {
      if (mounted) setState(() => _state = _ScanState.idle);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text(
          'Scanner un reçu',
          style: GoogleFonts.urbanist(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: _state == _ScanState.permissionDenied
          ? const _PermissionDeniedState()
          : _PickerState(
              picking: _state == _ScanState.picking,
              onCamera: _pickFromCamera,
              onGallery: _pickFromGallery,
            ),
    );
  }
}

class _PickerState extends StatelessWidget {
  const _PickerState({
    required this.picking,
    required this.onCamera,
    required this.onGallery,
  });

  final bool picking;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    if (picking) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              color: AppColors.accent,
              size: 64,
            ),
            const SizedBox(height: 24),
            _OptionButton(
              icon: Icons.camera_alt_outlined,
              label: 'Prendre une photo',
              onTap: onCamera,
            ),
            const SizedBox(height: 12),
            _OptionButton(
              icon: Icons.photo_library_outlined,
              label: 'Choisir depuis la galerie',
              onTap: onGallery,
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionDeniedState extends StatelessWidget {
  const _PermissionDeniedState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.no_photography_outlined,
              color: AppColors.textSecondary,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Accès à la caméra requis',
              style: GoogleFonts.urbanist(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Active l\'accès à la caméra dans les Réglages pour scanner tes reçus.',
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
                onPressed: openAppSettings,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Ouvrir les Réglages',
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

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.tonal(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.surfaceRaised,
          foregroundColor: AppColors.textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.urbanist(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
