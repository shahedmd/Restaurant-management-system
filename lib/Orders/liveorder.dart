// ignore_for_file: use_super_parameters, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:restaurant_management/controller/menucontroller.dart';
import '../controller/liverorderscontroller.dart';

class LiveOrdersPage extends StatelessWidget {
  LiveOrdersPage({Key? key}) : super(key: key);

  final LiveOrdersController controller = Get.put(
    LiveOrdersController(),
    permanent: true,
  );

  final Controller menucontroller = Get.put(Controller());

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
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

        Future.microtask(() => controller.checkForNewOrders(orders));

        if (orders.isEmpty) {
          return Center(
            child: Text(
              "No live orders",
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          );
        }

        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index].data() as Map<String, dynamic>;
            final docId = orders[index].id;
            final bool isSeen = order['isSeen'] ?? false;

            final items = List<Map<String, dynamic>>.from(order['items'] ?? []);
            final timestamp =
                order['timestamp'] is Timestamp
                    ? (order['timestamp'] as Timestamp).toDate()
                    : null;

            return Card(
              color: isSeen ? Colors.white : Colors.brown.shade800,
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ExpansionTile(
                key: ValueKey(
                  docId,
                ), // helps Flutter keep tile state per document
                title: Text(
                  "Table No: ${order['tableNo'] ?? 'N/A'}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSeen ? Colors.black : Colors.white,
                  ),
                ),
                subtitle: Text(
                  "Total: \$${order['total'] ?? 0} | Status: ${order['status'] ?? 'N/A'}",
                  style: TextStyle(
                    color: isSeen ? Colors.grey[700] : Colors.white70,
                  ),
                ),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blueAccent),
                      tooltip: 'Edit Order',
                      onPressed: () => _showEditDialog(context, docId, order),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      tooltip: 'Delete Order',
                      onPressed: () async {
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
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.print, color: Colors.green),
                      tooltip: 'Print Invoice',
                      onPressed: () {
                        menucontroller.showInvoiceDialog(context, order, docId);
                        Get.snackbar(
                          'Print',
                          'Invoice feature coming soon',
                          backgroundColor: Colors.blue.shade300,
                          colorText: Colors.white,
                        );
                      },
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
                  const Divider(),
                  ...items.map((item) {
                    return ListTile(
                      dense: true,
                      title: Text(
                        "${item['name']}  ×${item['quantity']}",
                        style: TextStyle(
                          color: isSeen ? Colors.black : Colors.white,
                        ),
                      ),
                      subtitle: Text(
                        "৳${item['price']}  |  Category: ${item['category'] ?? ''}",
                        style: TextStyle(
                          color: isSeen ? Colors.grey[700] : Colors.white70,
                        ),
                      ),
                    );
                  }),
                  if (timestamp != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "Order Time: ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}  •  ${timestamp.day}/${timestamp.month}/${timestamp.year}",
                        style: TextStyle(
                          fontSize: 13,
                          color: isSeen ? Colors.black54 : Colors.white70,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEditDialog(
    BuildContext context,
    String docId,
    Map<String, dynamic> order,
  ) {
    final status = RxString(order['status'] ?? 'pending');
    final feedbackController = TextEditingController(
      text: order['adminFeedback'] ?? '',
    );

    Get.dialog(
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
                    ['pending', 'processing', 'delivered']
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(s.capitalize!),
                          ),
                        )
                        .toList(),
                onChanged: (val) => status.value = val!,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: feedbackController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Admin Feedback',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Get.back()),
          ElevatedButton.icon(
            icon: const Icon(Icons.save, size: 18),
            label: const Text('Save'),
            onPressed: () async {
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
            },
          ),
        ],
      ),
    );
  }
}
