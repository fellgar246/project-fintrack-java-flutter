import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_controller.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../shared/strings/app_strings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.settingsTitle)),
      body: authState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text(AppStrings.genericError)),
        data: (state) => state.maybeWhen(
          authenticated: (user) => ListView(
            children: [
              ListTile(
                leading: CircleAvatar(
                  child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?'),
                ),
                title: Text(user.name),
                subtitle: Text(user.email),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: const Text(AppStrings.accountsTitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/settings/accounts'),
              ),
              ListTile(
                leading: const Icon(Icons.category_outlined),
                title: const Text(AppStrings.categoriesTitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/settings/categories'),
              ),
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: const Text(AppStrings.themeLabel),
                subtitle: Text(_themeLabel(themeMode)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(value: ThemeMode.light, label: Text(AppStrings.themeLight)),
                    ButtonSegment(value: ThemeMode.dark, label: Text(AppStrings.themeDark)),
                    ButtonSegment(value: ThemeMode.system, label: Text(AppStrings.themeSystem)),
                  ],
                  selected: {themeMode},
                  onSelectionChanged: (selection) {
                    ref.read(themeModeProvider.notifier).state = selection.first;
                  },
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text(AppStrings.logoutButton),
                onTap: () => _confirmLogout(context, ref),
              ),
            ],
          ),
          orElse: () => const Center(child: Text(AppStrings.genericError)),
        ),
      ),
    );
  }

  String _themeLabel(ThemeMode mode) => switch (mode) {
        ThemeMode.light => AppStrings.themeLight,
        ThemeMode.dark => AppStrings.themeDark,
        ThemeMode.system => AppStrings.themeSystem,
      };

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.logoutConfirmTitle),
        content: const Text(AppStrings.logoutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.logoutButton),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }
}
