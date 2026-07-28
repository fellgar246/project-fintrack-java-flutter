class ByCategoryModel {
  const ByCategoryModel({
    required this.categoryId,
    required this.name,
    required this.color,
    required this.icon,
    required this.total,
    required this.percent,
  });

  final String categoryId;
  final String name;
  final String color;
  final String icon;
  final String total;
  final double percent;

  factory ByCategoryModel.fromJson(Map<String, dynamic> json) => ByCategoryModel(
        categoryId: json['categoryId'] as String,
        name: json['name'] as String,
        color: json['color'] as String,
        icon: json['icon'] as String,
        total: json['total'] as String,
        percent: (json['percent'] as num).toDouble(),
      );
}
