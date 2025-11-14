import 'package:cloud_firestore/cloud_firestore.dart';

class MenuItemModel {
  final String category;
  final String imgUrl;
  final String name;
  final int price;

  MenuItemModel({
    required this.category,
    required this.imgUrl,
    required this.name,
    required this.price,
  });

  Map<String, dynamic> toMap() {
    return {
      "category": category,
      "imgUrl": imgUrl,
      "name": name,
      "price": price,
    };
  }

  factory MenuItemModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
     return MenuItemModel(
    name: data['name'] ?? '',
    category: data['category'] ?? '',
    price: data['price'] ?? 0,
    imgUrl: data['imgUrl'] ?? '',  
  );
  }
}
