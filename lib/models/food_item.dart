class FoodItem {
  final String id;
  final String name;
  final String category;
  final String recipe;
  final String image;
  final double price;

  FoodItem({
    required this.id,
    required this.name,
    required this.category,
    required this.recipe,
    required this.image,
    required this.price,
  });

  // Convert JSON to FoodItem
  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      recipe: json['recipe'] ?? '',
      image: json['image'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
    );
  }

  // Convert FoodItem to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'recipe': recipe,
      'image': image,
      'price': price,
    };
  }
}
