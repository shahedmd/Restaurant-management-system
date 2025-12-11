class MenuVariant {
  final String size;
  final double price;

  MenuVariant({
    required this.size,
    required this.price,
  });

  factory MenuVariant.fromMap(Map<String, dynamic> data) {
    return MenuVariant(
      size: data['size'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        'size': size,
        'price': price,
      };
}



class MenuItemModel {
  final String name;
  final String category;

  final double? price;
  final String imgUrl;

  final String description; // <-- NEW FIELD

  final List<MenuVariant>? variants;

  MenuVariant? selectedVariant;

  int quantity;

  MenuItemModel({
    required this.name,
    required this.category,
    this.price,
    required this.imgUrl,
    required this.description, // <-- ADD HERE
    this.variants,
    this.selectedVariant,
    this.quantity = 1,
  });

  factory MenuItemModel.fromDoc(Map<String, dynamic> data) {
    List<MenuVariant>? variantList;
    if (data['variants'] != null) {
      var v = data['variants'] as List<dynamic>;
      variantList = v.map((e) => MenuVariant.fromMap(e)).toList();
    }

    return MenuItemModel(
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      price: data['price'] != null ? (data['price']).toDouble() : null,
      imgUrl: data['imgUrl'] ?? '',
      description: data['description'] ?? '', // <-- ADD HERE
      variants: variantList,
      selectedVariant: null,
      quantity: data['quantity'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'category': category,
        'price': price,
        'imgUrl': imgUrl,
        'description': description, // <-- ADD HERE
        'variants': variants?.map((v) => v.toMap()).toList(),
        'selectedVariant': selectedVariant?.toMap(),
        'quantity': quantity,
      };
}


