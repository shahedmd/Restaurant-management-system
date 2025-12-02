// ignore_for_file: unnecessary_overrides, avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html; // for audio on web
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class OrderItem {
  final String name;
  final String? imgUrl;
  final String category;
  final int quantity;
  final num price;
  final Map<String, dynamic>? selectedVariant;
  final List<dynamic>? variants;

  OrderItem({
    required this.name,
    this.imgUrl,
    required this.category,
    required this.quantity,
    required this.price,
    required this.selectedVariant,
    this.variants,
  });

  factory OrderItem.fromMap(Map<String, dynamic> m) {
    final sel = m['selectedVariant'];
    num price = 0;
    if (sel is Map<String, dynamic>) {
      price = (sel['price'] as num?) ?? (m['price'] as num? ?? 0);
    } else {
      price = (m['price'] as num?) ?? 0;
    }
    return OrderItem(
      name: m['name']?.toString() ?? '',
      imgUrl: m['imgUrl']?.toString(),
      category: m['category']?.toString() ?? '',
      quantity: (m['quantity'] as num?)?.toInt() ?? 0,
      price: price,
      selectedVariant:
          sel is Map<String, dynamic> ? Map<String, dynamic>.from(sel) : null,
      variants: m['variants'] as List<dynamic>?,
    );
  }
}

class OrderModel {
  final String id;
  final String orderType;
  final String paymentMethod;
  final String? name;
  final String? phone;
  final String? address;
  final Timestamp? timestamp;
  final Timestamp? prebookSlot;
  final String status;
  final String tableNo;
  final num total;
  final String adminFeedback;
  final bool isSeen;
  final String transactionId;
  final List<OrderItem> items;
  final Map<String, dynamic> raw;

  OrderModel({
    required this.id,
    required this.orderType,
    required this.paymentMethod,
    this.name,
    this.phone,
    this.address,
    this.timestamp,
    this.prebookSlot,
    required this.status,
    required this.tableNo,
    required this.total,
    required this.adminFeedback,
    required this.isSeen,
    required this.transactionId,
    required this.items,
    required this.raw,
  });

  DateTime? get orderTime => timestamp?.toDate();
  DateTime? get prebookTime => prebookSlot?.toDate();

  factory OrderModel.fromDoc(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    final itemsRaw = (data['items'] as List<dynamic>?) ?? <dynamic>[];
    final items = itemsRaw
        .map((e) => OrderItem.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    return OrderModel(
      id: doc.id,
      orderType: data['orderType']?.toString() ?? 'Inhouse',
      paymentMethod: data['paymentMethod']?.toString() ?? '',
      name: data['name']?.toString(),
      phone: data['phone']?.toString(),
      address: data['address']?.toString(),
      timestamp: data['timestamp'] as Timestamp?,
      prebookSlot: data['prebookSlot'] as Timestamp?,
      status: data['status']?.toString() ?? 'pending',
      tableNo: data['tableNo']?.toString() ?? 'N/A',
      total: (data['total'] as num?) ?? 0,
      adminFeedback: data['adminFeedback']?.toString() ?? '',
      isSeen: data['isSeen'] as bool? ?? false,
      transactionId: data['transactionId']?.toString() ?? '',
      items: items,
      raw: data,
    );
  }
}

class LiveOrdersController extends GetxController {
  final RxList<OrderModel> orders = <OrderModel>[].obs;
  final RxBool loading = false.obs;

  // Audio element for web
  final html.AudioElement _audioElement = html.AudioElement()
    ..src =
        'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3' // Use short notification sound
    ..preload = 'auto';

  // Date formatter
  final DateFormat dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

  late final StreamSubscription<QuerySnapshot> _ordersSub;

  @override
  void onInit() {
    super.onInit();
    _startListener();
  }

  void _startListener() {
    final todayStart = DateTime.now();
    final today = DateTime(todayStart.year, todayStart.month, todayStart.day);

    final query = FirebaseFirestore.instance
        .collection('orders')
        .where('orderType', whereIn: ['Inhouse', 'Prebooking', 'Home Delivery'])
        .where('status', whereIn: ['pending', 'processing'])
        .orderBy('timestamp', descending: true)
        .limit(200);

    _ordersSub = query.snapshots().listen(
      (snap) {
        final mapped = snap.docs
            .map((d) => OrderModel.fromDoc(d))
            .where((o) {
          final ts = o.timestamp?.toDate();
          if (ts == null) return false;
          return ts.year == today.year &&
              ts.month == today.month &&
              ts.day == today.day;
        }).toList();

        // Detect new pending orders for snackbar & sound
        for (final o in mapped) {
          final exists = orders.any((e) => e.id == o.id);
          if (!exists && o.status == 'pending') {
            _playNotificationSound();
            Get.snackbar(
              "New Order",
              "${o.orderType} order received!\nTable: ${o.tableNo}\nPayment: ${o.paymentMethod}\nTxn ID: ${o.transactionId}",
              snackPosition: SnackPosition.TOP,
              backgroundColor: Colors.green.shade400,
              colorText: Colors.white,
              duration: const Duration(days: 1),
              isDismissible: false,
              mainButton: TextButton(
                onPressed: () {
                  if (Get.isSnackbarOpen) Get.back();
                },
                child: const Icon(Icons.close, color: Colors.white),
              ),
            );
          }
        }

        // Update observable list
        orders.assignAll(mapped);
      },
      onError: (e) {
        loading.value = false;
        Get.snackbar(
          "Error",
          "Failed to fetch orders: $e",
          backgroundColor: Colors.red.shade300,
          colorText: Colors.white,
        );
      },
    );
  }

  // Play short audio notification safely
  Future<void> _playNotificationSound() async {
    try {
      _audioElement.pause();
      _audioElement.currentTime = 0;
      await _audioElement.play();
      Future.delayed(const Duration(seconds: 2), () {
        _audioElement.pause();
        _audioElement.currentTime = 0;
      });
    } catch (e) {
      debugPrint("Audio play error: $e");
    }
  }

  Future<void> markSeen(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(docId).update({
        'isSeen': true,
      });
      final idx = orders.indexWhere((o) => o.id == docId);
      if (idx != -1) {
        final o = orders[idx];
        orders[idx] = OrderModel(
          id: o.id,
          orderType: o.orderType,
          paymentMethod: o.paymentMethod,
          name: o.name,
          phone: o.phone,
          address: o.address,
          timestamp: o.timestamp,
          prebookSlot: o.prebookSlot,
          status: o.status,
          tableNo: o.tableNo,
          total: o.total,
          adminFeedback: o.adminFeedback,
          isSeen: true,
          transactionId: o.transactionId,
          items: o.items,
          raw: o.raw,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateStatusAndFeedback(
      String docId, String status, String feedback) async {
    await FirebaseFirestore.instance.collection('orders').doc(docId).update({
      'status': status,
      'adminFeedback': feedback,
    });
  }

  Future<void> deleteOrder(String docId) async {
    await FirebaseFirestore.instance.collection('orders').doc(docId).delete();
  }

  @override
  void onClose() {
    _ordersSub.cancel();
    super.onClose();
  }
}
