// ignore_for_file: use_super_parameters, deprecated_member_use, prefer_const_constructors, use_build_context_synchronously, unnecessary_to_list_in_spreads

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

  final LiveOrdersController controller = Get.put(
    LiveOrdersController(),
    permanent: true,
  );
  final Controller menucontroller = Get.put(Controller());
  final SalesController salesController = Get.put(SalesController());

  final DateFormat _dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          " Live Orders",
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 2, 41, 87),
      ),
      body: Obx(() {
        final orders = controller.orders;

        if (orders.isEmpty) {
          return Center(
            child: Text(
              "No live orders",
              style: TextStyle(fontSize: 18.sp, color: Colors.grey[600]),
            ),
          );
        }

        return ListView.separated(
          padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
          itemCount: orders.length,
          separatorBuilder: (_, __) => SizedBox(height: 6.h),
          itemBuilder: (context, index) {
            final order = orders[index];
            return _buildOrderCard(context, order);
          },
        );
      }),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order) {
    final bool isSeen = order.isSeen;
    final bg = isSeen ? Colors.white : Colors.brown.shade800;
    final txtColor = isSeen ? Colors.black : Colors.white;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      color: bg,
      child: ExpansionTile(
        key: ValueKey(order.id),
        tilePadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        backgroundColor: bg,
        collapsedBackgroundColor: bg,
        childrenPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Table: ${order.tableNo}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                      color: txtColor,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    "${order.orderType}  •  ${_shortStatusLabel(order.status)}",
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: isSeen ? Colors.grey[700] : Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "৳${order.total.toString()}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                    color: txtColor,
                  ),
                ),
                SizedBox(height: 6.h),
                _statusChip(order.status),
              ],
            ),
          ],
        ),
        trailing: Wrap(
          spacing: 6.w,
          children: [
            _iconButton(
              onTap: () => _showEditDialog(context, order),
              icon: FontAwesomeIcons.edit,
              tooltip: 'Edit',
            ),
            _iconButton(
              onTap: () async {
                final success = await menucontroller.showInvoiceDialog(
                  context,
                  order.raw,
                  order.id,
                );
                if (!success) {
                  Get.snackbar(
                    "Error",
                    "Invoice failed",
                    backgroundColor: Colors.red,
                  );
                  return;
                }

                // fetch fresh order snapshot before adding sale
                final snap =
                    await FirebaseFirestore.instance
                        .collection('orders')
                        .doc(order.id)
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
                await salesController.addSale(
                  updatedOrder,
                  order.id,
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
                  try {
                    await controller.deleteOrder(order.id);
                    Get.snackbar(
                      'Deleted',
                      'Order removed successfully',
                      backgroundColor: Colors.red.shade300,
                      colorText: Colors.white,
                    );
                  } catch (e) {
                    Get.snackbar(
                      'Error',
                      'Delete failed: $e',
                      backgroundColor: Colors.red.shade300,
                      colorText: Colors.white,
                    );
                  }
                }
              },
              icon: FontAwesomeIcons.trash,
              tooltip: 'Delete',
              danger: true,
            ),
          ],
        ),
        onExpansionChanged: (expanded) async {
          if (expanded && !order.isSeen) {
            try {
              await controller.markSeen(order.id);
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
          // Big structured modern layout inside expansion
          _expandedContent(order),
          SizedBox(height: 12.h),
        ],
      ),
    );
  }

  Widget _expandedContent(OrderModel order) {
    final bool isSeen = order.isSeen;
    final txtColor = isSeen ? Colors.black : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row: Order meta (id, time, prebook)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Order ID: ${order.id}",
              style: TextStyle(fontSize: 13.sp, color: txtColor),
            ),
            if (order.orderTime != null)
              Text(
                _dateFormat.format(order.orderTime!),
                style: TextStyle(
                  fontSize: 12.sp,
                  color: isSeen ? Colors.black54 : Colors.white70,
                ),
              ),
          ],
        ),
        SizedBox(height: 8.h),
        // Two-column area: items list and details
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: isSeen ? Colors.grey.shade50 : Colors.brown.shade700,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order meta small line
              Wrap(
                spacing: 12.w,
                runSpacing: 6.h,
                children: [
                  _metaChip(
                    icon: FontAwesomeIcons.bolt,
                    label: order.orderType,
                  ),
                  _metaChip(
                    icon: FontAwesomeIcons.table,
                    label: 'Tables ${order.tableNo}',
                  ),
                  _metaChip(
                    icon: FontAwesomeIcons.clock,
                    label:
                        order.prebookTime != null
                            ? _dateFormat.format(order.prebookTime!)
                            : 'No prebook',
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Text(
                "Items",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14.sp,
                  color: txtColor,
                ),
              ),
              SizedBox(height: 6.h),
              ...order.items.map((it) => _buildItemRow(it, isSeen)).toList(),
              Divider(height: 18.h),
              // Customer info (only for Home Delivery & Prebooking)
              if (order.orderType == 'Home Delivery' ||
                  order.orderType == 'Prebooking') ...[
                Text(
                  "Customer Info",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.sp,
                    color: txtColor,
                  ),
                ),
                SizedBox(height: 6.h),
                _infoRow('Name', order.name ?? '—', isSeen),
                SizedBox(height: 6.h),
                _infoRow('Phone', order.phone ?? '—', isSeen),
                SizedBox(height: 6.h),
                _infoRow('Address', order.address ?? '—', isSeen),
                SizedBox(height: 12.h),
              ],
              // Payment info (always show payment-related fields)
              Text(
                "Payment",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14.sp,
                  color: txtColor,
                ),
              ),
              SizedBox(height: 6.h),
              _infoRow(
                'Method',
                order.paymentMethod.isNotEmpty ? order.paymentMethod : 'Cash',
                isSeen,
              ),
              SizedBox(height: 6.h),
              if (order.transactionId.isNotEmpty)
                _infoRow('Transaction ID', order.transactionId, isSeen),
              SizedBox(height: 12.h),

              // Admin Feedback
              Text(
                "Admin Feedback",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14.sp,
                  color: txtColor,
                ),
              ),
              SizedBox(height: 6.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: isSeen ? Colors.white : Colors.brown.shade600,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  order.adminFeedback.isNotEmpty
                      ? order.adminFeedback
                      : 'No feedback yet',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: isSeen ? Colors.black87 : Colors.white70,
                  ),
                ),
              ),
              SizedBox(height: 12.h),

              // Status + actions row
              Row(
                children: [
                  _statusChip(order.status),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _gradientActionButton(
                      label: 'Change Status',
                      icon: FontAwesomeIcons.exchangeAlt,
                      onTap: () => _showEditDialog(Get.context!, order),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: _gradientActionButton(
                      label: 'Print KOT',
                      icon: FontAwesomeIcons.print,
                      onTap:
                          () => menucontroller.showInvoiceDialog(
                            Get.context!,
                            order.raw,
                            order.id,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemRow(OrderItem it, bool isSeen) {
    final String variantLabel =
        (it.selectedVariant != null && it.selectedVariant!['size'] != null)
            ? it.selectedVariant!['size'].toString()
            : '';
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        children: [
          _buildItemImage(it.imgUrl),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${it.name} ${variantLabel.isNotEmpty ? '• $variantLabel' : ''}",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                    color: isSeen ? Colors.black : Colors.white,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  "${it.category}  •  x${it.quantity}",
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isSeen ? Colors.black54 : Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            "৳${(it.price * it.quantity).toString()}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13.sp,
              color: isSeen ? Colors.black : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _infoRow(String label, String value, bool isSeen) {
    return Row(
      children: [
        SizedBox(
          width: 100.w,
          child: Text(
            "$label:",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13.sp,
              color: isSeen ? Colors.black87 : Colors.white,
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13.sp,
              color: isSeen ? Colors.black87 : Colors.white70,
            ),
          ),
        ),
      ],
    );
  }

  Widget _metaChip({required IconData icon, required String label}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        color: Colors.white24,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, size: 12.sp, color: Colors.white),
          SizedBox(width: 6.w),
          Text(label, style: TextStyle(fontSize: 12.sp, color: Colors.black)),
        ],
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
      case 'cancelled':
        bg = Colors.grey.shade400;
        label = 'Cancelled';
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
  Future<void> _showEditDialog(BuildContext context, OrderModel order) async {
    final LiveOrdersController c = controller;
    final RxString status = RxString(order.status);
    final TextEditingController feedbackController = TextEditingController(
      text: order.adminFeedback,
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
                await c.updateStatusAndFeedback(
                  order.id,
                  status.value,
                  feedbackController.text,
                );
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
