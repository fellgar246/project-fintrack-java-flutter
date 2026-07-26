import 'package:flutter/material.dart';

/// Provisional Phase 0 screen: only confirms that the route navigates.
/// Each feature replaces this with its real UI in its own phase.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title, this.footer});

  final String title;

  /// Optional widget rendered below the title — e.g. a logout button on
  /// `/settings`, ahead of that screen getting its real implementation.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            if (footer != null) ...[
              const SizedBox(height: 16),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}
