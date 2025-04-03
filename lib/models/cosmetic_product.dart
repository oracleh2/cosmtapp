class CosmeticProduct {
  final int id;
  final String name;
  final String brand;
  final String? imageUrl;
  final String category;
  final List<String> ingredients;
  final String? description;
  final double? rating;
  final String? recommendationReason;
  final String? skinTypeTarget;
  final List<String>? skinConcernsTarget;

  CosmeticProduct({
    required this.id,
    required this.name,
    required this.brand,
    this.imageUrl,
    required this.category,
    required this.ingredients,
    this.description,
    this.rating,
    this.recommendationReason,
    this.skinTypeTarget,
    this.skinConcernsTarget,
  });

  factory CosmeticProduct.fromJson(Map<String, dynamic> json) {
    List<String> parseStringList(List<dynamic> data) {
      return data.map((item) => item.toString()).toList();
    }

    return CosmeticProduct(
      id: json['id'],
      name: json['name'],
      brand: json['brand'],
      imageUrl: json['image_url'],
      category: json['category'],
      ingredients: parseStringList(json['ingredients']),
      description: json['description'],
      rating: json['rating']?.toDouble(),
      recommendationReason: json['recommendation_reason'],
      skinTypeTarget: json['skin_type_target'],
      skinConcernsTarget: json['skin_concerns_target'] != null
          ? parseStringList(json['skin_concerns_target'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'image_url': imageUrl,
      'category': category,
      'ingredients': ingredients,
      'description': description,
      'rating': rating,
      'recommendation_reason': recommendationReason,
      'skin_type_target': skinTypeTarget,
      'skin_concerns_target': skinConcernsTarget,
    };
  }
}