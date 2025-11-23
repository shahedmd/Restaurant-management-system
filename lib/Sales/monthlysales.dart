// ignore_for_file: avoid_types_as_parameter_names

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'controller.dart'; // SalesController with generateMonthlySalesPDF

class MonthlySalesPage extends StatefulWidget {
  const MonthlySalesPage({super.key});

  @override
  State<MonthlySalesPage> createState() => _MonthlySalesPageState();
}

class _MonthlySalesPageState extends State<MonthlySalesPage> {
  final salesController = Get.put(SalesController());
  String searchMonth = "";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8f8f8),
      appBar: AppBar(
        title: const Text(
          "Monthly Sales",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 0, 24, 66),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: 600.w,
              child: TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: "Search by month (MM/yyyy)",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => searchMonth = v.trim()),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('monthlySales')
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No monthly sales found"));
                }

                // Map docs
                final months =
                    snapshot.data!.docs.map((doc) {
                      final data = doc.data()! as Map<String, dynamic>;
                      final ordersRaw = data['orders'] ?? [];
                      final orders =
                          ordersRaw
                              .map<Map<String, dynamic>>(
                                (e) => Map<String, dynamic>.from(e),
                              )
                              .toList();
                      return {
                        'monthId': doc.id, // e.g., '2025-11'
                        'orders': orders,
                      };
                    }).toList();

                // Filter by searchMonth
                final filteredMonths =
                    months.where((monthData) {
                      final monthId = monthData['monthId'];
                      final formatted = DateFormat('MM/yyyy').format(
                        DateTime(
                          int.parse(monthId.split('-')[0]),
                          int.parse(monthId.split('-')[1]),
                        ),
                      );
                      return formatted.contains(searchMonth);
                    }).toList();

                if (filteredMonths.isEmpty) {
                  return const Center(child: Text("No sales for this month"));
                }

                // Sort descending
                filteredMonths.sort(
                  (a, b) => b['monthId'].compareTo(a['monthId']),
                );

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredMonths.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final monthData = filteredMonths[index];
                    final month = monthData['monthId'];
                    final orders =
                        monthData['orders'] as List<Map<String, dynamic>>;

                    final grandTotal = orders.fold<int>(
                      0,
                      (sum, o) => sum + ((o['total'] ?? 0) as num).toInt(),
                    );

                    return Card(
                      child: ListTile(
                        title: Text(
                          "Month: $month",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text("Total Sales: $grandTotal৳"),
                        trailing: Obx(
                          () => IconButton(
                            icon:
                                salesController.isLoading.value
                                    ? const CircularProgressIndicator()
                                    : const Icon(
                                      Icons.picture_as_pdf,
                                      color: Colors.blueAccent,
                                    ),
                            onPressed:
                                salesController.isLoading.value
                                    ? null
                                    : () => salesController
                                        .generateMonthlySalesPDF(orders, month),
                          ),
                        ),
                        onTap: () {
                          // Compute daily totals
                          Map<String, int> dailyTotals = {};
                          for (var sale in orders) {
                            final time =
                                (sale['timestamp'] as Timestamp).toDate();
                            final day = DateFormat('dd MMM yyyy').format(time);

                            final total =
                                (sale['total'] ?? 0)
                                    as num; // total can be int or double
                            dailyTotals[day] =
                                ((dailyTotals[day] ?? 0) + total)
                                    .toInt(); // cast sum to int
                          }

                          final sortedDays =
                              dailyTotals.keys.toList()..sort(
                                (a, b) => b.compareTo(a),
                              ); // newest first

                          showDialog(
                            context: context,
                            builder:
                                (_) => AlertDialog(
                                  title: Text("Daily Sales for $month"),
                                  content: SizedBox(
                                    width: 650.w,
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: sortedDays.length,
                                      itemBuilder: (_, i) {
                                        final day = sortedDays[i];
                                        final total = dailyTotals[day];
                                        return ListTile(
                                          title: Text(day),
                                          trailing: Text(
                                            "$total৳",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text("Close"),
                                    ),
                                  ],
                                ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
