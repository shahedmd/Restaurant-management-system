// ignore_for_file: depend_on_referenced_packages, deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:convert';
import 'dart:typed_data';
import 'dart:html' as html;
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class MenuGetxCtrl extends GetxController {
  @override
  void onInit() {
    super.onInit();
    fetchCategories();
  }

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  RxString searchQuery = "".obs;

  // Firestore item lists
  RxList<QueryDocumentSnapshot> allItems = <QueryDocumentSnapshot>[].obs;
  RxList<QueryDocumentSnapshot> filteredItems = <QueryDocumentSnapshot>[].obs;

  String currentCollection = "menu";

  // Categories loaded from categories/categorylist
  RxList<String> categories = <String>[].obs;

  // ============================================================
  // FETCH CATEGORY LIST
  // ============================================================
  Future<void> fetchCategories() async {
    final doc = await _db.collection("category").doc("VPSKqsQRbOLyz1aOloSG").get();

    if (doc.exists) {
      final list = List<String>.from(doc["categorylist"] ?? []);
      categories.value = list;
    }
  }

  // ============================================================
  // STREAM ITEMS
  // ============================================================
  Stream<QuerySnapshot> fetchItems({required String collection}) {
    currentCollection = collection;

    return _db.collection(collection).snapshots().map((snapshot) {
      allItems.value = snapshot.docs;
      applyFilter();
      return snapshot;
    });
  }

  // ============================================================
  // FILTER
  // ============================================================
  void applyFilter() {
    String q = searchQuery.value.trim().toLowerCase();

    if (q.isEmpty) {
      filteredItems.value = allItems;
      return;
    }

    filteredItems.value = allItems.where((doc) {
      final data = doc.data() as Map<String, dynamic>;

      final name = data["name"]?.toString().toLowerCase() ?? "";
      final category = data["category"]?.toString().toLowerCase() ?? "";
      final description = data["description"]?.toString().toLowerCase() ?? "";

      return name.contains(q) || category.contains(q) || description.contains(q);
    }).toList();
  }

  // ============================================================
  // IMAGE PICKER (WEB)
  // ============================================================
  Future<Uint8List?> pickImageWeb() async {
    final uploadInput = html.FileUploadInputElement()..accept = 'image/*';
    uploadInput.click();
    await uploadInput.onChange.first;

    final file = uploadInput.files!.first;
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);

    await reader.onLoadEnd.first;
    return reader.result as Uint8List?;
  }

  // ============================================================
  // IMGBB UPLOAD
  // ============================================================
  Future<String> uploadToImgbb(Uint8List bytes) async {
    const apiKey = "d31defbd1e775a2d2f576bf33fcdc446";
    final url = Uri.parse("https://api.imgbb.com/1/upload?key=$apiKey");

    final base64Image = base64Encode(bytes);
    final res = await http.post(url, body: {"image": base64Image});
    final data = jsonDecode(res.body);

    return data["data"]["url"];
  }

  // ============================================================
  // CREATE ITEM — now includes description
  // ============================================================
  Future<void> createItem({
    required String name,
    int? price,
    List<Map<String, dynamic>>? variants,
    required Uint8List imageBytes,
    String? category,
    DateTime? validate,
    required String collection,
    String description = "",
  }) async {
    final String imageUrl = await uploadToImgbb(imageBytes);

    Map<String, dynamic> data = {
      "name": name,
      "imgUrl": imageUrl,
      "description": description,
    };

    // Single price
    if (price != null) data["price"] = price;

    // Variants list
    if (variants != null && variants.isNotEmpty) data["variants"] = variants;

    if (category != null) data["category"] = category;
    if (validate != null) data["validate"] = validate;

    await _db.collection(collection).add(data);
  }

  // ============================================================
  // UPDATE ITEM — now includes description
  // ============================================================
  Future<void> updateItem({
    required String docId,
    required String name,
    int? price,
    List<Map<String, dynamic>>? variants,
    required String imgUrl,
    String? category,
    DateTime? validate,
    required String collection,
    String description = "",
  }) async {
    Map<String, dynamic> data = {
      "name": name,
      "imgUrl": imgUrl,
      "description": description,
    };

    // Single-price
    if (price != null) {
      data["price"] = price;
    } else {
      data.remove("price");
    }

    // Variant-price
    if (variants != null && variants.isNotEmpty) {
      data["variants"] = variants;
    } else {
      data.remove("variants");
    }

    if (category != null) data["category"] = category;
    if (validate != null) data["validate"] = validate;

    await _db.collection(collection).doc(docId).update(data);
  }

  // ============================================================
  // DELETE
  // ============================================================
  Future<void> deleteItem({
    required String docId,
    required String collection,
  }) async {
    await _db.collection(collection).doc(docId).delete();
  }
}
