import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/categories_api.dart';
import '../data/models/category_model.dart';

class CategoriesFilter {
  const CategoriesFilter({
    this.kind = CategoryKind.expense,
    this.includeArchived = false,
  });

  final CategoryKind? kind;
  final bool includeArchived;

  CategoriesFilter copyWith({
    CategoryKind? kind,
    bool? includeArchived,
  }) {
    return CategoriesFilter(
      kind: kind ?? this.kind,
      includeArchived: includeArchived ?? this.includeArchived,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoriesFilter &&
          kind == other.kind &&
          includeArchived == other.includeArchived;

  @override
  int get hashCode => Object.hash(kind, includeArchived);
}

final categoriesFilterProvider =
    StateProvider<CategoriesFilter>((ref) => const CategoriesFilter());

class CategoriesController extends AsyncNotifier<List<CategoryModel>> {
  @override
  Future<List<CategoryModel>> build() async {
    final filter = ref.watch(categoriesFilterProvider);
    return ref.read(categoriesApiProvider).list(
          kind: filter.kind,
          includeArchived: filter.includeArchived,
        );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final filter = ref.read(categoriesFilterProvider);
      return ref.read(categoriesApiProvider).list(
            kind: filter.kind,
            includeArchived: filter.includeArchived,
          );
    });
  }

  Future<void> create({
    required String name,
    required CategoryKind kind,
    required String color,
    required String icon,
  }) async {
    await ref.read(categoriesApiProvider).create(
          name: name,
          kind: kind,
          color: color,
          icon: icon,
        );
    ref.invalidateSelf();
  }

  Future<void> updateCategory({
    required String id,
    required String name,
    required String color,
    required String icon,
  }) async {
    await ref.read(categoriesApiProvider).update(
          id: id,
          name: name,
          color: color,
          icon: icon,
        );
    ref.invalidateSelf();
  }

  Future<void> delete(String id) async {
    await ref.read(categoriesApiProvider).delete(id);
    ref.invalidateSelf();
  }
}

final categoriesControllerProvider =
    AsyncNotifierProvider<CategoriesController, List<CategoryModel>>(
  CategoriesController.new,
);
