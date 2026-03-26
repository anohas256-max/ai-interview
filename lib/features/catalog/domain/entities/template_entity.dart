class TemplateEntity {
  final int id;
  final String title;
  final String description;
  final String price;
  final String? imageUrl;
  final String categoryName;
  final String mode; // 👈 ВОТ ОНО, САМОЕ ГЛАВНОЕ ПОЛЕ!

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
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: json['price'] ?? '0.00',
      imageUrl: json['image_url'], 
      categoryName: json['category'] != null ? json['category']['name'] : '',
      mode: json['mode'] ?? 'roleplay', // 👈 И ВОТ ЗДЕСЬ МЫ ЕГО ЧИТАЕМ
    );
  }
}