class Category {
  final String id;
  final String title;
  final String icon;
  final bool enabled;

  const Category({
    required this.id,
    required this.title,
    required this.icon,
    required this.enabled,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      title: json['title'] as String,
      icon: (json['icon'] as String?) ?? '❓',
      enabled: (json['enabled'] as bool?) ?? true,
    );
  }
}
