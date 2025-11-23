// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserCancelledOrdersPage extends StatefulWidget {
  const UserCancelledOrdersPage({super.key});

  @override
  State<UserCancelledOrdersPage> createState() =>
      _UserCancelledOrdersPageState();
}

class _UserCancelledOrdersPageState extends State<UserCancelledOrdersPage> {
  DateTime? selectedDate;
  String searchText = "";

  Stream<QuerySnapshot> getCancelledOrdersStream() {
    final start = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      0,
      0,
      0,
    );

    final end = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      23,
      59,
      59,
    );

    return FirebaseFirestore.instance
        .collection('cancelledOrders')
        .where('status', isEqualTo: 'cancelled')
        .where('cancelledAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('cancelledAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('cancelledAt', descending: true)
        .snapshots();
  }

  @override
  void initState() {
    selectedDate = DateTime.now();
    super.initState();
  }

  Future<void> pickDate() async {
    final DateTime? newDate = await showDatePicker(
      context: context,
      initialDate: selectedDate!,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );

    if (newDate != null) {
      setState(() => selectedDate = newDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 2, 41, 87),
        title: Text(
          " User Cancelled Orders",
          style: TextStyle(
            fontSize: 18.sp,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(
              children: [
                // Search Field
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "Search by Table No...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    onChanged: (v) => setState(() => searchText = v.trim()),
                  ),
                ),

                SizedBox(width: 10.w),

                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 10.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    DateFormat('dd MMM yyyy').format(selectedDate!),
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                SizedBox(width: 10.w),

                // Calendar Icon Button
                InkWell(
                  onTap: pickDate,
                  child: Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: const Icon(
                      Icons.calendar_month,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: getCancelledOrdersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                final docs = snapshot.data?.docs ?? [];

                final filtered =
                    docs.where((doc) {
                      final order = doc.data()! as Map<String, dynamic>;
                      final tableNo =
                          (order['tableNo'] ?? '').toString().toLowerCase();
                      return tableNo.contains(searchText.toLowerCase());
                    }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text("No orders found"));
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16.w),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final order =
                        filtered[index].data() as Map<String, dynamic>;

                    final cancelledTime =
                        order['cancelledAt'] != null
                            ? DateFormat('dd MMM yyyy hh:mm a').format(
                              (order['cancelledAt'] as Timestamp).toDate(),
                            )
                            : "N/A";

                    return Card(
                      margin: EdgeInsets.only(bottom: 14.h),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(12.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Table: ${order['tableNo'] ?? '-'}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.sp,
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10.w,
                                    vertical: 5.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Text(
                                    "Cancelled",
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 4.h),
                            Text("Order Type: ${order['orderType'] ?? '-'}"),
                            Text("Cancelled At: $cancelledTime"),

                            Divider(height: 12.h),

                            // Item List
                            ...List.generate((order['items'] as List).length, (
                              i,
                            ) {
                              final item =
                                  (order['items'] as List)[i]
                                      as Map<String, dynamic>;

                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: CachedNetworkImage(
                                  imageUrl: item['imgUrl'],
                                  width: 45.w,
                                  height: 45.h,
                                  fit: BoxFit.cover,
                                ),
                                title: Text(
                                  "${item['name']} ×${item['quantity']}",
                                  style: TextStyle(fontSize: 13.sp),
                                ),
                                subtitle: Text(
                                  "Category: ${item['category']}",
                                  style: TextStyle(fontSize: 11.sp),
                                ),
                                trailing: Text(
                                  "BDT${item['price']}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.sp,
                                  ),
                                ),
                              );
                            }),

                            Divider(height: 12.h),

                            Text(
                              "Total Amount: BDT${order['total']}",
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            if ((order['adminFeedback'] ?? '').isNotEmpty)
                              Text(
                                "Feedback: ${order['adminFeedback']}",
                                style: TextStyle(fontSize: 12.sp),
                              ),
                          ],
                        ),
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
