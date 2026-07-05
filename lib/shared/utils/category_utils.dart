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
      'success'              => (const Color(0xFF063D28), AppColors.success),
      'accent'               => (AppColors.accentDim, AppColors.accent),
      'danger'               => (const Color(0xFF3D1010), AppColors.danger),
      'warning'              => (const Color(0xFF3A2A00), AppColors.warning),
      'text-secondary'       => (AppColors.surfaceRaised, AppColors.textSecondary),
      'cat-custom-rose'      => (const Color(0xFF3D1533), const Color(0xFFFF6BAF)),
      'cat-custom-teal'      => (const Color(0xFF0A2B2B), const Color(0xFF00C2A8)),
      'cat-custom-terracotta'=> (const Color(0xFF3D1A0A), const Color(0xFFE07A5F)),
      'cat-custom-olive'     => (const Color(0xFF1E2A0A), const Color(0xFF8DB53E)),
      'cat-custom-slate'     => (const Color(0xFF1A1F30), const Color(0xFF7B8EC8)),
      'cat-custom-prune'     => (const Color(0xFF280A3D), const Color(0xFFB57BFF)),
      _                      => (AppColors.surfaceRaised, AppColors.textSecondary),
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
      // icônes du picker custom (Story 5.2)
      'star'              => Icons.star,
      'favorite'          => Icons.favorite,
      'bolt'              => Icons.bolt,
      'local_cafe'        => Icons.local_cafe,
      'sports_soccer'     => Icons.sports_soccer,
      'music_note'        => Icons.music_note,
      'fitness_center'    => Icons.fitness_center,
      'work'              => Icons.work,
      'pets'              => Icons.pets,
      'flight'            => Icons.flight,
      'palette'           => Icons.palette,
      'devices'           => Icons.devices,
      'local_florist'     => Icons.local_florist,
      'sports_esports'    => Icons.sports_esports,
      'beach_access'      => Icons.beach_access,
      'kitchen'           => Icons.kitchen,
      _                   => Icons.category,
    };
  }
}
