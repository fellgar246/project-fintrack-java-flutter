import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../shared/strings/app_strings.dart';
import '../../../shared/widgets/async_list_scaffold.dart';
import '../data/models/category_model.dart';
import '../providers/categories_provider.dart';
import 'category_form_sheet.dart';
import 'widgets/category_tile.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final kind = _tabController.index == 0 ? CategoryKind.expense : CategoryKind.income;
    ref.read(categoriesFilterProvider.notifier).state =
        ref.read(categoriesFilterProvider).copyWith(kind: kind);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  CategoryKind get _currentKind =>
      _tabController.index == 0 ? CategoryKind.expense : CategoryKind.income;

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesControllerProvider);
    final filter = ref.watch(categoriesFilterProvider);

    Future<void> confirmDelete(String id, String name) async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(AppStrings.deleteCategoryTitle),
          content: Text(AppStrings.deleteCategoryMessage(name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(AppStrings.cancelButton),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(AppStrings.deleteAction),
            ),
          ],
        ),
      );

      if (confirmed != true || !context.mounted) return;

      try {
        await ref.read(categoriesControllerProvider.notifier).delete(id);
      } on ApiException catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.detail)));
      }
    }

    return AsyncListScaffold(
      title: AppStrings.categoriesTitle,
      isLoading: categoriesAsync.isLoading,
      error: categoriesAsync.hasError ? categoriesAsync.error : null,
      isEmpty: categoriesAsync.hasValue && categoriesAsync.requireValue.isEmpty,
      onRetry: () => ref.read(categoriesControllerProvider.notifier).refresh(),
      emptyTitle: AppStrings.categoriesEmpty,
      emptyActionLabel: AppStrings.createFirstCategory,
      onEmptyAction: () => showCategoryFormSheet(context, defaultKind: _currentKind),
      actions: [
        FilterChip(
          label: const Text(AppStrings.showArchived),
          selected: filter.includeArchived,
          onSelected: (selected) {
            ref.read(categoriesFilterProvider.notifier).state =
                filter.copyWith(includeArchived: selected);
          },
        ),
        const SizedBox(width: 8),
      ],
      floatingActionButton: FloatingActionButton(
        onPressed: () => showCategoryFormSheet(context, defaultKind: _currentKind),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: AppStrings.expenseTab),
              Tab(text: AppStrings.incomeTab),
            ],
          ),
          Expanded(
            child: categoriesAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (categories) => ListView.builder(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return CategoryTile(
                    category: category,
                    onTap: () => showCategoryFormSheet(context, category: category),
                    onDelete: () => confirmDelete(category.id, category.name),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
