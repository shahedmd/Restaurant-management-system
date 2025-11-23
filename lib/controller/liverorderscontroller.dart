// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LiveOrdersController extends GetxController {
  RxSet<String> notifiedOrders = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _listenOrders(); // call your Firestore subscription here
  }

  void _listenOrders() {
    FirebaseFirestore.instance
        .collection('orders')
        .where('orderType', whereIn: ['Inhouse', 'Prebooking'])
        .where('status', whereIn: ['pending', 'processing'])
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      checkForNewOrders(snapshot.docs); // pass snapshot docs to your existing method
    });
  }

  void checkForNewOrders(List<QueryDocumentSnapshot> orders) {
    for (var order in orders) {
      final docId = order.id;
      final data = order.data() as Map<String, dynamic>;
      final bool isSeen = data['isSeen'] ?? false;

      if (!isSeen && !notifiedOrders.contains(docId)) {
        Get.snackbar(
          "🛎️ New Order!",
          "Table No: ${data['tableNo'] ?? 'N/A'}",
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green.withOpacity(0.9),
          colorText: Colors.white,
          isDismissible: true,
          duration: null,
          mainButton: TextButton(
            onPressed: () => Get.back(),
            child: const Text("Close", style: TextStyle(color: Colors.white)),
          ),
        );
        notifiedOrders.add(docId);
      }
    }
  }
}
