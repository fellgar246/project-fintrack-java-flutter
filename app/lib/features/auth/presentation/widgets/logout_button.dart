import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/strings/app_strings.dart';
import '../../providers/auth_controller.dart';

class LogoutButton extends ConsumerWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FilledButton.tonalIcon(
      onPressed: () => ref.read(authControllerProvider.notifier).logout(),
      icon: const Icon(Icons.logout),
      label: const Text(AppStrings.logoutButton),
    );
  }
}
