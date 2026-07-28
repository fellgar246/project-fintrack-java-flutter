import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../shared/strings/app_strings.dart';
import '../../categories/data/categories_api.dart';
import '../../categories/data/models/category_model.dart';
import '../../transactions/presentation/widgets/category_picker_grid.dart';
import '../data/models/budget_model.dart';
import '../providers/budgets_provider.dart';

final budgetFormCategoriesProvider =
    FutureProvider.autoDispose<List<CategoryModel>>((ref) {
  return ref.read(categoriesApiProvider).list(
        kind: CategoryKind.expense,
        includeArchived: false,
      );
});

Future<void> showBudgetFormSheet(
  BuildContext context, {
  required String yearMonth,
  BudgetModel? budget,
  String? preselectedCategoryId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => BudgetFormSheet(
      yearMonth: yearMonth,
      budget: budget,
      preselectedCategoryId: preselectedCategoryId,
    ),
  );
}

class BudgetFormSheet extends ConsumerStatefulWidget {
  const BudgetFormSheet({
    super.key,
    required this.yearMonth,
    this.budget,
    this.preselectedCategoryId,
  });

  final String yearMonth;
  final BudgetModel? budget;
  final String? preselectedCategoryId;

  @override
  ConsumerState<BudgetFormSheet> createState() => _BudgetFormSheetState();
}

class _BudgetFormSheetState extends ConsumerState<BudgetFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _limitController;
  String? _selectedCategoryId;
  bool _submitting = false;

  bool get _isEditing => widget.budget?.hasBudget ?? false;

  @override
  void initState() {
    super.initState();
    _limitController = TextEditingController(
      text: widget.budget?.limitAmount ?? '',
    );
    _selectedCategoryId =
        widget.budget?.category.id ?? widget.preselectedCategoryId;
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) return;

    setState(() => _submitting = true);
    try {
      await ref.read(budgetsProvider(widget.yearMonth).notifier).upsert(
            categoryId: _selectedCategoryId!,
            limitAmount: _limitController.text.trim(),
          );

      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.detail)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(budgetFormCategoriesProvider);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEditing ? AppStrings.editBudgetTitle : AppStrings.newBudgetTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              if (!_isEditing) ...[
                Text(
                  AppStrings.categoryLabel,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                categoriesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, _) => const Text(AppStrings.genericError),
                  data: (categories) => CategoryPickerGrid(
                    categories: categories,
                    selectedId: _selectedCategoryId,
                    onSelected: (id) => setState(() => _selectedCategoryId = id),
                    errorText: _selectedCategoryId == null && _submitting
                        ? AppStrings.categoryRequired
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
              ] else ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: _parseColor(widget.budget!.category.color),
                    child: const Icon(Icons.category, color: Colors.white),
                  ),
                  title: Text(widget.budget!.category.name),
                ),
                const SizedBox(height: 8),
              ],
              TextFormField(
                controller: _limitController,
                decoration: const InputDecoration(labelText: AppStrings.budgetLimitLabel),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppStrings.amountRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEditing ? AppStrings.saveButton : AppStrings.createButton),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    final normalized = hex.replaceFirst('#', '');
    return Color(int.parse('FF$normalized', radix: 16));
  }
}
