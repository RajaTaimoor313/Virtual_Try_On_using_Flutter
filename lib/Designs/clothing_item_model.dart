class ClothingItem {
  final int? id;
  final String name;
  final String category;
  final String imagePath;
  final String? description;
  final double? price;
  final String? modelPath;

  ClothingItem({
    this.id,
    required this.name,
    required this.category,
    required this.imagePath,
    this.description,
    this.price,
    this.modelPath,
  });

  factory ClothingItem.fromMap(Map<String, dynamic> map) {
    return ClothingItem(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      imagePath: map['image_path'],
      description: map['description'],
      price: map['price'],
      modelPath: map['model_path'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'image_path': imagePath,
      'description': description,
      'price': price,
      'model_path': modelPath,
    };
  }
}
