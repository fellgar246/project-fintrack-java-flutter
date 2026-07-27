import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../shared/icons/material_icon_helper.dart';
import '../../../shared/strings/app_strings.dart';
import '../data/models/category_model.dart';
import '../providers/categories_provider.dart';

Future<void> showCategoryFormSheet(
  BuildContext context, {
  CategoryModel? category,
  CategoryKind? defaultKind,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => CategoryFormSheet(
      category: category,
      defaultKind: defaultKind,
    ),
  );
}

class CategoryFormSheet extends ConsumerStatefulWidget {
  const CategoryFormSheet({
    super.key,
    this.category,
    this.defaultKind,
  });

  final CategoryModel? category;
  final CategoryKind? defaultKind;

  @override
  ConsumerState<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<CategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _hexController;
  late String _color;
  late String _icon;
  bool _submitting = false;

  bool get _isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _color = widget.category?.color ?? CategoryColorPalette.colors.first;
    _icon = widget.category?.icon ?? MaterialIconHelper.curatedIcons.first;
    _hexController = TextEditingController(text: _color);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hexController.dispose();
    super.dispose();
  }

  void _selectColor(String color) {
    setState(() {
      _color = color;
      _hexController.text = color;
    });
  }

  void _applyHexColor() {
    final value = _hexController.text.trim();
    if (RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(value)) {
      setState(() => _color = value.toUpperCase());
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _applyHexColor();

    setState(() => _submitting = true);
    try {
      final controller = ref.read(categoriesControllerProvider.notifier);
      final name = _nameController.text.trim();

      if (_isEditing) {
        await controller.updateCategory(
          id: widget.category!.id,
          name: name,
          color: _color,
          icon: _icon,
        );
      } else {
        final kind = widget.defaultKind ?? CategoryKind.expense;
        await controller.create(name: name, kind: kind, color: _color, icon: _icon);
      }

      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      final message = e.isConflict ? AppStrings.categoryNameConflict : e.detail;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                _isEditing ? AppStrings.editCategoryTitle : AppStrings.newCategoryTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: AppStrings.categoryNameLabel),
                textCapitalization: TextCapitalization.sentences,
                validator: (value) =>
                    value == null || value.trim().isEmpty ? AppStrings.nameRequired : null,
              ),
              const SizedBox(height: 16),
              Text(AppStrings.colorLabel, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: CategoryColorPalette.colors.map((color) {
                  final selected = _color.toUpperCase() == color.toUpperCase();
                  return GestureDetector(
                    onTap: _submitting ? null : () => _selectColor(color),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Color(int.parse('FF${color.replaceFirst('#', '')}', radix: 16)),
                        shape: BoxShape.circle,
                        border: selected
                            ? Border.all(color: Theme.of(context).colorScheme.primary, width: 3)
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _hexController,
                decoration: const InputDecoration(
                  labelText: AppStrings.hexColorLabel,
                  hintText: '#FF7043',
                ),
                onFieldSubmitted: (_) => _applyHexColor(),
              ),
              const SizedBox(height: 16),
              Text(AppStrings.iconLabel, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              SizedBox(
                height: 160,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: MaterialIconHelper.curatedIcons.length,
                  itemBuilder: (context, index) {
                    final iconName = MaterialIconHelper.curatedIcons[index];
                    final selected = _icon == iconName;
                    return InkWell(
                      onTap: _submitting ? null : () => setState(() => _icon = iconName),
                      borderRadius: BorderRadius.circular(8),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: selected
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(MaterialIconHelper.resolve(iconName)),
                      ),
                    );
                  },
                ),
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
}
