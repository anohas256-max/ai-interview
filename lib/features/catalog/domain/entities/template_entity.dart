class TemplateEntity {
  final int id;
  final String title;
  final String description;
  final String price;
  final String? imageUrl;
  final String categoryName;
  final String mode;

  TemplateEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    this.imageUrl,
    required this.categoryName,
    required this.mode,
  });

  factory TemplateEntity.fromJson(Map<String, dynamic> json) {
    return TemplateEntity(
      // 👇 Теперь мы безопасно парсим любые типы, даже если пришел null 👇
      id: json['id'] as int? ?? 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: json['price']?.toString() ?? '0.00',
      imageUrl: json['image_url']?.toString(), 
      categoryName: json['category'] != null ? json['category']['name']?.toString() ?? '' : '',
      mode: json['mode']?.toString() ?? 'roleplay',
    );
  }
}