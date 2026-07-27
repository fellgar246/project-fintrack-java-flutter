import 'package:flutter/material.dart';

import '../../../../shared/icons/material_icon_helper.dart';
import '../../../../shared/strings/app_strings.dart';
import '../../data/models/category_model.dart';

class CategoryTile extends StatelessWidget {
  const CategoryTile({
    super.key,
    required this.category,
    required this.onTap,
    required this.onDelete,
  });

  final CategoryModel category;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  Color get _backgroundColor {
    final hex = category.color.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(category.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Theme.of(context).colorScheme.errorContainer,
        child: Icon(Icons.archive_outlined, color: Theme.of(context).colorScheme.onErrorContainer),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: _backgroundColor,
          child: Icon(
            MaterialIconHelper.resolve(category.icon),
            color: Colors.white,
          ),
        ),
        title: Text(category.name),
        trailing: PopupMenuButton<String>(
          onSelected: (_) => onDelete(),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'delete',
              child: Text(AppStrings.deleteAction),
            ),
          ],
        ),
      ),
    );
  }
}
