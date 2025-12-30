import 'category.dart';

class CategoryDetail {
  final Category category;
  final String subtitle;
  final String description;
  final int questionCount;
  final int points;
  final int packCount;

  const CategoryDetail({
    required this.category,
    required this.subtitle,
    required this.description,
    required this.questionCount,
    required this.points,
    required this.packCount,
  });
}
