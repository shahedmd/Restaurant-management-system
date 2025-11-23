// ignore_for_file: use_super_parameters, deprecated_member_use, prefer_const_constructors, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:restaurant_management/Sales/controller.dart';

import 'package:restaurant_management/controller/menucontroller.dart';
import '../controller/liverorderscontroller.dart';

class LiveOrdersPage extends StatelessWidget {
  LiveOrdersPage({Key? key}) : super(key: key);

  // Controllers (GetX)
  final LiveOrdersController controller = Get.put(
    LiveOrdersController(),
    permanent: true,
  );

  // Menu controller (for invoice / printing etc)
  final Controller menucontroller = Get.put(Controller());

  // Date formatter
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

  final SalesController salesController = Get.put(SalesController());

  @override
  Widget build(BuildContext context) {
    // ScreenUtil should already be initialized in main.dart via ScreenUtilInit
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 2, 41, 87),
        title: Text(
          " Live Orders",
          style: TextStyle(
            fontSize: 18.sp,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('orders')
                .where('orderType', whereIn: ['Inhouse', 'Prebooking'])
                .where('status', whereIn: ['pending', 'processing'])
                .orderBy('timestamp', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data!.docs;

          // If your LiveOrdersController has a checkForNewOrders method (used previously)
          // call it sparingly to avoid extra overhead.
          // Wrapping in microtask to avoid interfering with build.

          if (orders.isEmpty) {
            return Center(
              child: Text(
                "No live orders",
                style: TextStyle(fontSize: 18.sp, color: Colors.grey[600]),
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final doc = orders[index];
              final docId = doc.id;
              final order =
                  (doc.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
              final bool isSeen = order['isSeen'] as bool? ?? false;
              final itemsList =
                  (order['items'] as List<dynamic>?)
                      ?.cast<Map<String, dynamic>>() ??
                  <Map<String, dynamic>>[];
              final Timestamp? ts = order['timestamp'] as Timestamp?;
              final DateTime? orderTime = ts?.toDate();
              final Timestamp? prebookTs = order['prebookSlot'] as Timestamp?;
              final DateTime? prebookTime = prebookTs?.toDate();
              final String status = order['status'] as String? ?? 'pending';
              final String tableNo = order['tableNo']?.toString() ?? 'N/A';
              final num total = order['total'] as num? ?? 0;
              final String orderType =
                  order['orderType'] as String? ?? 'Inhouse';
              final String adminFeedback =
                  order['adminFeedback'] as String? ?? '';

              return Padding(
                padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 10.w),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  color: isSeen ? Colors.white : Colors.brown.shade800,
                  child: ExpansionTile(
                    key: ValueKey(docId),
                    tilePadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    childrenPadding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                    backgroundColor:
                        isSeen ? Colors.white : Colors.brown.shade800,
                    collapsedBackgroundColor:
                        isSeen ? Colors.white : Colors.brown.shade800,
                    title: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Table: $tableNo",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.sp,
                                  color: isSeen ? Colors.black : Colors.white,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                "$orderType  •  ${_shortStatusLabel(status)}",
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color:
                                      isSeen
                                          ? Colors.grey[700]
                                          : Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "৳${total.toString()}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14.sp,
                                color: isSeen ? Colors.black : Colors.white,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            _statusChip(status),
                          ],
                        ),
                      ],
                    ),
                    trailing: Wrap(
                      spacing: 6.w,
                      children: [
                        _iconButton(
                          onTap: () => _showEditDialog(context, docId, order),
                          icon: FontAwesomeIcons.edit,
                          tooltip: 'Edit',
                        ),

                        _iconButton(
                          onTap: () async {
                            // 1️⃣ Print invoice & update order
                            final success = await menucontroller
                                .showInvoiceDialog(context, order, docId);

                            if (!success) {
                              Get.snackbar(
                                "Error",
                                "Invoice failed",
                                backgroundColor: Colors.red,
                              );
                              return;
                            }

                            // 2️⃣ Fetch fresh data AFTER invoice has updated the order
                            final snap =
                                await FirebaseFirestore.instance
                                    .collection('orders')
                                    .doc(docId)
                                    .get();

                            if (!snap.exists) {
                              Get.snackbar(
                                "Error",
                                "Order not found",
                                backgroundColor: Colors.red,
                              );
                              return;
                            }

                            final updatedOrder = snap.data()!;

                            // 3️⃣ Now add sale using the fresh correct data
                            await salesController.addSale(
                              updatedOrder,
                              docId,
                              updatedOrder['name'],
                              updatedOrder['phone'],
                            );
                          },
                          icon: FontAwesomeIcons.print,
                          tooltip: 'Print',
                        ),

                        _iconButton(
                          onTap: () async {
                            final confirm = await _confirmDelete(context);
                            if (confirm == true) {
                              await FirebaseFirestore.instance
                                  .collection('orders')
                                  .doc(docId)
                                  .delete();
                              Get.snackbar(
                                'Deleted',
                                'Order removed successfully',
                                backgroundColor: Colors.red.shade300,
                                colorText: Colors.white,
                              );
                            }
                          },
                          icon: FontAwesomeIcons.trash,
                          tooltip: 'Delete',
                          danger: true,
                        ),
                      ],
                    ),
                    onExpansionChanged: (expanded) async {
                      if (expanded && !isSeen) {
                        try {
                          await FirebaseFirestore.instance
                              .collection('orders')
                              .doc(docId)
                              .update({'isSeen': true});
                        } catch (e) {
                          Get.snackbar(
                            'Error',
                            'Could not mark order seen: $e',
                            backgroundColor: Colors.red.shade300,
                            colorText: Colors.white,
                          );
                        }
                      }
                    },
                    children: [
                      // Items list
                      ...itemsList.map((item) {
                        final String itemName = item['name']?.toString() ?? '';
                        final String? imgUrl = item['imgUrl']?.toString();
                        final String category =
                            item['category']?.toString() ?? '';
                        final int qty =
                            (item['quantity'] as num?)?.toInt() ?? 0;

                        // Price resolution: selectedVariant.price -> item['price'] -> 0
                        num itemPrice = 0;
                        final selVariant = item['selectedVariant'];
                        if (selVariant is Map<String, dynamic>) {
                          itemPrice = selVariant['price'] as num? ?? 0;
                        } else {
                          itemPrice = item['price'] as num? ?? 0;
                        }

                        final String variantLabel =
                            (selVariant is Map<String, dynamic>)
                                ? (selVariant['size']?.toString() ?? '')
                                : '';

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: _buildItemImage(imgUrl),
                          title: Text(
                            "$itemName ${variantLabel.isNotEmpty ? '• $variantLabel' : ''}",
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: isSeen ? Colors.black : Colors.white,
                            ),
                          ),
                          subtitle: Text(
                            "$category  •  ৳${itemPrice.toString()}  •  x$qty",
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: isSeen ? Colors.grey[700] : Colors.white70,
                            ),
                          ),
                          trailing: Text(
                            "৳${(itemPrice * qty).toString()}",
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                              color: isSeen ? Colors.black : Colors.white,
                            ),
                          ),
                        );
                      }),

                      Divider(height: 12.h),

                      // Timestamps & Prebook slot if any
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (orderTime != null)
                              Text(
                                "Order Time: ${_dateFormat.format(orderTime)}",
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color:
                                      isSeen ? Colors.black54 : Colors.white70,
                                ),
                              ),
                            if (prebookTime != null) SizedBox(height: 6.h),
                            if (prebookTime != null)
                              Text(
                                "Prebooking Slot: ${_dateFormat.format(prebookTime)}",
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color:
                                      isSeen ? Colors.black54 : Colors.white70,
                                ),
                              ),
                            SizedBox(height: 8.h),
                            Row(
                              children: [
                                Expanded(
                                  child: _gradientActionButton(
                                    label: 'Change Status',
                                    icon: FontAwesomeIcons.exchangeAlt,
                                    onTap:
                                        () => _showEditDialog(
                                          context,
                                          docId,
                                          order,
                                        ),
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: _gradientActionButton(
                                    label: 'Print KOT',
                                    icon: FontAwesomeIcons.print,
                                    onTap:
                                        () => menucontroller.showInvoiceDialog(
                                          context,
                                          order,
                                          docId,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10.h),
                            // Admin feedback area (display)
                            Text(
                              "Admin Feedback:",
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: isSeen ? Colors.black : Colors.white,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(10.h),
                              decoration: BoxDecoration(
                                color:
                                    isSeen
                                        ? Colors.grey.shade100
                                        : Colors.brown.shade700,
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text(
                                adminFeedback.isNotEmpty
                                    ? adminFeedback
                                    : 'No feedback yet',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color:
                                      isSeen ? Colors.black87 : Colors.white70,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12.h),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // -------------------------
  // UI Helper Widgets
  // -------------------------
  Widget _buildItemImage(String? url) {
    const double size = 48;
    if (url == null || url.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.fastfood, size: 20),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8.r),
      child: CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder:
            (c, s) => Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        errorWidget:
            (c, s, e) => Container(
              width: size,
              height: size,
              color: Colors.grey.shade200,
              child: Icon(Icons.broken_image, size: 20),
            ),
      ),
    );
  }

  Widget _iconButton({
    required VoidCallback onTap,
    required IconData icon,
    required String tooltip,
    bool danger = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.r),
          color: Colors.transparent,
        ),
        child: FaIcon(
          icon,
          size: 18.sp,
          color: danger ? Colors.redAccent : Colors.blueAccent,
        ),
      ),
    );
  }

  Widget _gradientActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        height: 42.h,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.blue.shade700],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(8.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              offset: Offset(0, 3),
              blurRadius: 6,
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(icon, size: 14.sp, color: Colors.white),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    Color bg;
    String label;
    switch (status) {
      case 'processing':
        bg = Colors.orange.shade200;
        label = 'Processing';
        break;
      case 'delivered':
        bg = Colors.green.shade200;
        label = 'Delivered';
        break;
      case 'pending':
      default:
        bg = Colors.red.shade200;
        label = 'Pending';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _shortStatusLabel(String status) {
    switch (status) {
      case 'processing':
        return 'Processing';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.capitalizeFirst ?? status;
    }
  }

  // -------------------------
  // Dialogs
  // -------------------------
  Future<void> _showEditDialog(
    BuildContext context,
    String docId,
    Map<String, dynamic> order,
  ) async {
    final RxString status = RxString(order['status']?.toString() ?? 'pending');
    final TextEditingController feedbackController = TextEditingController(
      text: order['adminFeedback']?.toString() ?? '',
    );

    await Get.dialog(
      AlertDialog(
        title: const Text('Edit Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(
              () => DropdownButtonFormField<String>(
                value: status.value,
                decoration: const InputDecoration(labelText: 'Status'),
                items:
                    ['pending', 'processing', 'cancelled', 'delivered']
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(s.capitalize!),
                          ),
                        )
                        .toList(),
                onChanged: (val) {
                  if (val != null) status.value = val;
                },
              ),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: feedbackController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Admin Feedback',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton.icon(
            icon: const Icon(Icons.save, size: 18),
            label: const Text('Save'),
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('orders')
                    .doc(docId)
                    .update({
                      'status': status.value,
                      'adminFeedback': feedbackController.text,
                    });
                Get.back();
                Get.snackbar(
                  'Success',
                  'Order updated successfully',
                  backgroundColor: Colors.green.shade400,
                  colorText: Colors.white,
                );
              } catch (e) {
                Get.snackbar(
                  'Error',
                  'Failed to update: $e',
                  backgroundColor: Colors.red.shade300,
                  colorText: Colors.white,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirm delete'),
        content: const Text(
          'Are you sure you want to delete this order? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Get.back(result: true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
