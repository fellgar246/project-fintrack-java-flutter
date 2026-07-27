import 'package:flutter/material.dart';

/// Maps backend Material icon names to [IconData] for category tiles and pickers.
class MaterialIconHelper {
  MaterialIconHelper._();

  static const curatedIcons = <String>[
    'restaurant',
    'directions_bus',
    'home',
    'bolt',
    'local_hospital',
    'movie',
    'shopping_bag',
    'school',
    'payments',
    'work',
    'trending_up',
    'add_circle',
    'account_balance_wallet',
    'credit_card',
    'savings',
    'attach_money',
    'receipt',
    'local_cafe',
    'fitness_center',
    'pets',
    'flight',
    'hotel',
    'phone',
    'wifi',
    'child_care',
    'build',
    'car_repair',
    'local_grocery_store',
    'fastfood',
    'celebration',
    'favorite',
  ];

  static IconData resolve(String name) {
    return switch (name) {
      'restaurant' => Icons.restaurant,
      'directions_bus' => Icons.directions_bus,
      'home' => Icons.home,
      'bolt' => Icons.bolt,
      'local_hospital' => Icons.local_hospital,
      'movie' => Icons.movie,
      'shopping_bag' => Icons.shopping_bag,
      'school' => Icons.school,
      'payments' => Icons.payments,
      'work' => Icons.work,
      'trending_up' => Icons.trending_up,
      'add_circle' => Icons.add_circle,
      'account_balance_wallet' => Icons.account_balance_wallet,
      'credit_card' => Icons.credit_card,
      'savings' => Icons.savings,
      'attach_money' => Icons.attach_money,
      'receipt' => Icons.receipt,
      'local_cafe' => Icons.local_cafe,
      'fitness_center' => Icons.fitness_center,
      'pets' => Icons.pets,
      'flight' => Icons.flight,
      'hotel' => Icons.hotel,
      'phone' => Icons.phone,
      'wifi' => Icons.wifi,
      'child_care' => Icons.child_care,
      'build' => Icons.build,
      'car_repair' => Icons.car_repair,
      'local_grocery_store' => Icons.local_grocery_store,
      'fastfood' => Icons.fastfood,
      'celebration' => Icons.celebration,
      'favorite' => Icons.favorite,
      _ => Icons.label_outline,
    };
  }
}

/// Preset palette for category color selection (~12 options).
class CategoryColorPalette {
  CategoryColorPalette._();

  static const colors = <String>[
    '#FF7043',
    '#42A5F5',
    '#8D6E63',
    '#FFCA28',
    '#EF5350',
    '#AB47BC',
    '#26A69A',
    '#5C6BC0',
    '#4CAF50',
    '#66BB6A',
    '#9CCC65',
    '#26C6DA',
  ];
}
