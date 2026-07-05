import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

class FabMenuSheet extends StatelessWidget {
  const FabMenuSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
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
        const SizedBox(height: 8),
        _MenuItem(
          icon: Icons.qr_code_scanner_outlined,
          label: 'Scan Reçu',
          enabled: true,
          onTap: () => Navigator.of(context).pop('scan_receipt'),
        ),
        const Divider(color: AppColors.border, indent: 16, endIndent: 16, height: 1),
        _MenuItem(
          icon: Icons.add_circle_outline,
          label: 'Nouvelle transaction',
          enabled: true,
          onTap: () => Navigator.of(context).pop('new_transaction'),
        ),
        SizedBox(height: MediaQuery.paddingOf(context).bottom + 8),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? AppColors.textPrimary : AppColors.textDisabled;

    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color, size: 24),
      title: Text(
        label,
        style: GoogleFonts.urbanist(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
      minLeadingWidth: 24,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
