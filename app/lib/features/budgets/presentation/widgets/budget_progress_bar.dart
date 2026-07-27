import 'package:flutter/material.dart';

import '../../data/models/budget_model.dart';

class BudgetProgressBar extends StatelessWidget {
  const BudgetProgressBar({
    super.key,
    required this.percentUsed,
    required this.status,
    this.height = 8,
  });

  final double percentUsed;
  final BudgetStatus status;
  final double height;

  Color get _color => switch (status) {
        BudgetStatus.ok => Colors.green.shade600,
        BudgetStatus.warning => Colors.amber.shade700,
        BudgetStatus.exceeded => Colors.red.shade700,
      };

  @override
  Widget build(BuildContext context) {
    final fillFraction = (percentUsed / 100).clamp(0.0, 1.0).toDouble();
    final showOverage = status == BudgetStatus.exceeded && percentUsed > 100;

    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Container(color: Theme.of(context).colorScheme.surfaceContainerHighest),
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              tween: Tween(begin: 0, end: fillFraction),
              builder: (context, value, _) => FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: value,
                child: Container(color: _color),
              ),
            ),
            if (showOverage)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 3,
                  color: Colors.red.shade900,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
