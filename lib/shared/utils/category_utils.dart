import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

abstract final class CategoryUtils {
  static const _categoryVisuals = <String, (String icon, String colorToken)>{
    'Alimentation':         ('restaurant',        'success'),
    'Transport':            ('directions_bus',    'accent'),
    'Santé & Pharmacie':    ('local_hospital',    'danger'),
    'Hygiène & Entretien':  ('cleaning_services', 'text-secondary'),
    'Logement & Factures':  ('home',              'text-secondary'),
    'Éducation':            ('school',            'text-secondary'),
    'Loisirs & Sorties':    ('celebration',       'warning'),
    'Habillement':          ('checkroom',         'text-secondary'),
    'Transferts & Épargne': ('savings',           'accent'),
    'Autre':                ('more_horiz',        'text-secondary'),
  };

  /// Retourne (iconName, colorToken) depuis le nom de catégorie (chaîne BFF/Mistral).
  static (String icon, String colorToken) categoryVisuals(String name) =>
      _categoryVisuals[name] ?? ('more_horiz', 'text-secondary');

  /// Retourne (bg, fg) pour une pastille catégorie selon son colorToken.
  static (Color bg, Color fg) pastilleColors(String colorToken) {
    return switch (colorToken) {
      'success'        => (const Color(0xFF063D28), AppColors.success),
      'accent'         => (AppColors.accentDim, AppColors.accent),
      'danger'         => (const Color(0xFF3D1010), AppColors.danger),
      'warning'        => (const Color(0xFF3A2A00), AppColors.warning),
      'text-secondary' => (AppColors.surfaceRaised, AppColors.textSecondary),
      _                => (AppColors.surfaceRaised, AppColors.textSecondary),
    };
  }

  /// Retourne l'IconData Material correspondant au nom d'icône stocké en base.
  static IconData iconData(String iconName) {
    return switch (iconName) {
      'restaurant'        => Icons.restaurant,
      'directions_bus'    => Icons.directions_bus,
      'local_hospital'    => Icons.local_hospital,
      'cleaning_services' => Icons.cleaning_services,
      'home'              => Icons.home,
      'school'            => Icons.school,
      'celebration'       => Icons.celebration,
      'checkroom'         => Icons.checkroom,
      'savings'           => Icons.savings,
      'more_horiz'        => Icons.more_horiz,
      _                   => Icons.category,
    };
  }
}
