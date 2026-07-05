import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../../../shared/data/database/app_database.dart';
import '../../../shared/providers/category_list_provider.dart';
import '../../../shared/providers/database_provider.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/utils/category_utils.dart';

/// Retourne true si `name` (trimmed, insensible à la casse) existe dans `existing`.
/// En mode édition, passer `excludeId` pour ne pas compter la catégorie en cours comme doublon.
bool isDuplicate(String name, List<Category> existing, {String? excludeId}) {
  final lower = name.trim().toLowerCase();
  return existing.any((c) => c.id != excludeId && c.name.toLowerCase() == lower);
}

const _kColorPalette = <(String, String)>[
  ('cat-custom-rose',        'Rose'),
  ('cat-custom-teal',        'Sarcelle'),
  ('cat-custom-terracotta',  'Terracotta'),
  ('cat-custom-olive',       'Olive'),
  ('cat-custom-slate',       'Ardoise'),
  ('cat-custom-prune',       'Prune'),
];

const _kPickerIconNames = <String>[
  'star',           'favorite',      'bolt',          'local_cafe',
  'sports_soccer',  'music_note',    'fitness_center', 'work',
  'pets',           'flight',        'palette',        'devices',
  'local_florist',  'sports_esports','beach_access',  'kitchen',
];

class CategoryFormSheet extends ConsumerStatefulWidget {
  const CategoryFormSheet({super.key, this.initial});

  /// null = mode création ; non null = mode édition (pré-rempli)
  final Category? initial;

  @override
  ConsumerState<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<CategoryFormSheet> {
  late final TextEditingController _nameCtrl;
  late String _selectedIcon;
  late String _selectedColorToken;
  bool _saving = false;

  bool get _isEditMode => widget.initial != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initial?.name ?? '');
    _selectedIcon = widget.initial?.icon ?? _kPickerIconNames.first;
    _selectedColorToken = widget.initial?.colorToken ?? _kColorPalette.first.$1;
    _nameCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final existing = ref.watch(categoryListProvider).asData?.value ?? [];
    final name = _nameCtrl.text.trim();
    final nameEmpty = name.isEmpty;
    final nameDuplicate = !nameEmpty &&
        isDuplicate(name, existing, excludeId: widget.initial?.id);
    final canSave = !nameEmpty && !nameDuplicate && !_saving;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        height: MediaQuery.sizeOf(context).height * 0.82,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
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
              _isEditMode ? 'Modifier la catégorie' : 'Nouvelle catégorie',
              style: GoogleFonts.urbanist(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Icône',
                      style: GoogleFonts.urbanist(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _IconPickerGrid(
                      iconNames: _kPickerIconNames,
                      selectedIcon: _selectedIcon,
                      selectedColorToken: _selectedColorToken,
                      onSelect: (icon) => setState(() => _selectedIcon = icon),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Couleur',
                      style: GoogleFonts.urbanist(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ColorPaletteRow(
                      selected: _selectedColorToken,
                      onSelect: (token) =>
                          setState(() => _selectedColorToken = token),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _nameCtrl,
                      style: GoogleFonts.urbanist(
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Nom de la catégorie',
                        hintStyle: GoogleFonts.urbanist(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                        ),
                        filled: true,
                        fillColor: AppColors.surfaceRaised,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: nameDuplicate
                                ? AppColors.danger
                                : AppColors.border,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: nameDuplicate
                                ? AppColors.danger
                                : AppColors.accent,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    if (nameDuplicate) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Cette catégorie existe déjà.',
                        style: GoogleFonts.urbanist(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.paddingOf(context).bottom + 20,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: canSave ? _save : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    disabledBackgroundColor: AppColors.accentDim,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _isEditMode ? 'Enregistrer' : 'Créer',
                          style: GoogleFonts.urbanist(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() => _isEditMode ? _update() : _create();

  Future<void> _create() async {
    setState(() => _saving = true);
    try {
      await ref.read(databaseProvider).categoryDao.insertCategory(
            CategoriesCompanion.insert(
              id: const Uuid().v4(),
              name: _nameCtrl.text.trim(),
              isPredefined: const Value(false),
              icon: _selectedIcon,
              colorToken: _selectedColorToken,
              createdAt: DateTime.now().millisecondsSinceEpoch,
            ),
          );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _update() async {
    setState(() => _saving = true);
    try {
      await ref.read(databaseProvider).categoryDao.updateCategory(
            widget.initial!.id,
            name: _nameCtrl.text.trim(),
            icon: _selectedIcon,
            colorToken: _selectedColorToken,
          );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _IconPickerGrid extends StatelessWidget {
  const _IconPickerGrid({
    required this.iconNames,
    required this.selectedIcon,
    required this.selectedColorToken,
    required this.onSelect,
  });

  final List<String> iconNames;
  final String selectedIcon;
  final String selectedColorToken;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = CategoryUtils.pastilleColors(selectedColorToken);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: iconNames.length,
      itemBuilder: (_, i) {
        final name = iconNames[i];
        final selected = name == selectedIcon;
        return GestureDetector(
          onTap: () => onSelect(name),
          child: Semantics(
            label: name,
            button: true,
            child: Container(
              decoration: BoxDecoration(
                color: bg,
                shape: BoxShape.circle,
                border: selected
                    ? Border.all(color: AppColors.accent, width: 2)
                    : null,
              ),
              child: Icon(
                CategoryUtils.iconData(name),
                color: fg,
                size: 22,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ColorPaletteRow extends StatelessWidget {
  const _ColorPaletteRow({required this.selected, required this.onSelect});

  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _kColorPalette.map((entry) {
        final (token, label) = entry;
        final isSelected = token == selected;
        final (_, fg) = CategoryUtils.pastilleColors(token);
        return GestureDetector(
          onTap: () => onSelect(token),
          child: Semantics(
            label: label,
            button: true,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: fg,
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(color: AppColors.textPrimary, width: 2)
                    : Border.all(color: Colors.transparent, width: 2),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
