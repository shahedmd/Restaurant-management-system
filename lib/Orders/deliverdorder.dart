// delivered_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // for formatting timestamp

import '../controller/menucontroller.dart';

class Deliverdorder extends StatelessWidget {
  Deliverdorder({super.key});

  final Controller controller = Get.put(Controller());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('orders')
                .where('status', isEqualTo: 'delivered')
                .orderBy('timestamp', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No delivered orders found"));
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index].data() as Map<String, dynamic>;
              final timestamp = order['timestamp'] as Timestamp?;
              final orderTime =
                  timestamp != null
                      ? DateFormat(
                        'dd/MM/yyyy hh:mm a',
                      ).format(timestamp.toDate())
                      : 'N/A';

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Customer: ${order['name'] ?? 'N/A'}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "Total: BDT${order['total'] ?? 0}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text("Phone: ${order['phone'] ?? 'N/A'}"),
                      Text("Order Type: ${order['orderType'] ?? 'N/A'}"),
                      Text("Table: ${order['tableNo'] ?? '-'}"),
                      Text("Order Time: $orderTime"), // ✅ Order time added
                      const Divider(),

                      // Order items
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: (order['items'] as List).length,
                        itemBuilder: (context, itemIndex) {
                          final item = (order['items'] as List)[itemIndex];
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("${item['name']} ×${item['quantity']}"),
                              Text("BDT${item['price']}"),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.download, size: 18),
                          label: const Text("Generate Invoice"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () async {
                            await controller.printingController
                                .generateInvoicePDF(
                                  order,
                                  (order['total'] ?? 0).toDouble(),
                                  0, // discount is 0 since already delivered
                                  {
                                    'name': order['name'] ?? '',
                                    'mobile': order['phone'] ?? '',
                                  },
                                );
                          },
                        ),
                      ),
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
}
