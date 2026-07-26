import 'package:flutter/material.dart';

/// Shown while `authControllerProvider` is still bootstrapping (reading the
/// token storage for the first time). Keeps the router from ever having to
/// pick between `/login` and `/dashboard` before it actually knows.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
