import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/database/app_database.dart';
import '../providers/category_list_provider.dart';
import '../theme/app_colors.dart';
import '../utils/category_utils.dart';

class CategorySelectorSheet extends ConsumerWidget {
  const CategorySelectorSheet({super.key, this.selectedId});

  final String? selectedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoryListProvider);

    return categoriesAsync.when(
      loading: () => const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, e) => const SizedBox(
        height: 300,
        child: Center(child: Icon(Icons.error_outline, color: AppColors.danger)),
      ),
      data: (cats) {
        final predefined = cats.where((c) => c.isPredefined).toList();
        final custom = cats.where((c) => !c.isPredefined).toList();

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (_, controller) => Column(
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
                'Catégorie',
                style: GoogleFonts.urbanist(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _CategoryGrid(
                      categories: predefined,
                      selectedId: selectedId,
                      onSelect: (cat) => Navigator.of(context).pop(cat),
                    ),
                    if (custom.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(color: AppColors.border),
                      ),
                      _CategoryGrid(
                        categories: custom,
                        selectedId: selectedId,
                        onSelect: (cat) => Navigator.of(context).pop(cat),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.categories,
    required this.selectedId,
    required this.onSelect,
  });

  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<Category> onSelect;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 8,
        childAspectRatio: 0.75,
      ),
      itemCount: categories.length,
      itemBuilder: (_, i) {
        final cat = categories[i];
        return _CategoryPastilleCell(
          category: cat,
          isSelected: cat.id == selectedId,
          onTap: () => onSelect(cat),
        );
      },
    );
  }
}

class _CategoryPastilleCell extends StatelessWidget {
  const _CategoryPastilleCell({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  final Category category;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = CategoryUtils.pastilleColors(category.colorToken);
    final iconData = CategoryUtils.iconData(category.icon);

    return GestureDetector(
      onTap: onTap,
      child: Semantics(
        label: category.name,
        button: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: bg,
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(color: AppColors.accent, width: 2)
                    : null,
              ),
              child: Icon(iconData, color: fg, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              category.name,
              style: GoogleFonts.urbanist(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
