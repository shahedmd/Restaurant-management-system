// ignore_for_file: depend_on_referenced_packages, deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:convert';
import 'dart:typed_data';
import 'dart:html' as html;
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class MenuGetxCtrl extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  RxString searchQuery = "".obs;

  // Full list of items fetched from Firestore
  RxList<QueryDocumentSnapshot> allItems = <QueryDocumentSnapshot>[].obs;

  // Filtered list for UI
  RxList<QueryDocumentSnapshot> filteredItems = <QueryDocumentSnapshot>[].obs;

  String currentCollection = "menu"; // default collection

  // -------------------- STREAM FETCH --------------------
  Stream<QuerySnapshot> fetchItems({required String collection}) {
    currentCollection = collection; // set current collection
    return _db.collection(collection).snapshots().map((snapshot) {
      allItems.value = snapshot.docs;
      applyFilter();
      return snapshot;
    });
  }

  // -------------------- FILTERING LOGIC --------------------
  void applyFilter() {
    String query = searchQuery.value.toLowerCase();

    if (query.isEmpty) {
      filteredItems.value = allItems;
      return;
    }

    filteredItems.value = allItems.where((doc) {
      final data = doc.data() as Map<String, dynamic>;

      final name = data["name"].toString().toLowerCase();
      final category = data.containsKey("category") ? data["category"].toString().toLowerCase() : "";

      return name.contains(query) || category.contains(query);
    }).toList();
  }

  // -------- IMAGE PICK (WEB) --------
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

  // -------- UPLOAD TO IMGBB --------
  Future<String> uploadToImgbb(Uint8List bytes) async {
    const apiKey = "d31defbd1e775a2d2f576bf33fcdc446"; // your key
    final url = Uri.parse("https://api.imgbb.com/1/upload?key=$apiKey");
    final base64Image = base64Encode(bytes);

    final res = await http.post(url, body: {"image": base64Image});
    final data = jsonDecode(res.body);

    return data["data"]["url"];
  }

  // ---------------- CREATE ----------------
  Future<void> createItem({
    required String name,
    required int price,
    required Uint8List imageBytes,
    String? category,     // menu only
    DateTime? validate,   // offers only
    required String collection, // menu or offers
  }) async {
    String imageUrl = await uploadToImgbb(imageBytes);

    Map<String, dynamic> data = {
      "name": name,
      "price": price,
      "imgUrl": imageUrl,
    };

    if (category != null) data["category"] = category;
    if (validate != null) data["validate"] = validate;

    await _db.collection(collection).add(data);
  }

  // ---------------- UPDATE ----------------
  Future<void> updateItem({
    required String docId,
    required String name,
    required int price,
    required String imgUrl,
    String? category,     // menu only
    DateTime? validate,   // offers only
    required String collection, // menu or offers
  }) async {
    Map<String, dynamic> data = {
      "name": name,
      "price": price,
      "imgUrl": imgUrl,
    };

    if (category != null) data["category"] = category;
    if (validate != null) data["validate"] = validate;

    await _db.collection(collection).doc(docId).update(data);
  }

  // ---------------- DELETE ----------------
  Future<void> deleteItem({
    required String docId,
    required String collection, // menu or offers
  }) async {
    await _db.collection(collection).doc(docId).delete();
  }
}
