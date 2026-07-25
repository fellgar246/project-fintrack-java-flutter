import 'package:flutter/material.dart';

/// Pantalla provisional de la Fase 0: solo confirma que la ruta navega.
/// Cada feature reemplaza esto por su UI real en su propia fase.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
      ),
    );
  }
}
