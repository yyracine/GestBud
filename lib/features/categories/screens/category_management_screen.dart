import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../shared/data/database/app_database.dart';
import '../../../shared/providers/category_list_provider.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/utils/category_utils.dart';

List<Category> sortCategories(List<Category> all) {
  final predefined = all.where((c) => c.isPredefined).toList();
  final custom = all.where((c) => !c.isPredefined).toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  return [...predefined, ...custom];
}

class CategoryManagementScreen extends ConsumerWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoryListProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Mes catégories',
          style: GoogleFonts.urbanist(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accent,
        onPressed: () {},
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(
          child: Icon(Icons.error_outline, color: AppColors.danger),
        ),
        data: (all) {
          final sorted = sortCategories(all);
          if (sorted.isEmpty) return const SizedBox.shrink();
          return ListView.separated(
            itemCount: sorted.length,
            separatorBuilder: (_, _) =>
                const Divider(color: AppColors.border, height: 1),
            itemBuilder: (_, i) => _CategoryTile(category: sorted[i]),
          );
        },
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category});

  final Category category;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = CategoryUtils.pastilleColors(category.colorToken);
    final icon = CategoryUtils.iconData(category.icon);

    return Semantics(
      label: category.name,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Icon(icon, color: fg, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                category.name,
                style: GoogleFonts.urbanist(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (!category.isPredefined) ...[
              IconButton(
                icon: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.textSecondary,
                  size: 24,
                ),
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                tooltip: 'Renommer',
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.danger,
                  size: 24,
                ),
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                tooltip: 'Supprimer',
              ),
            ],
          ],
        ),
      ),
    );
  }
}
