// ignore_for_file: deprecated_member_use
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CancelledOrdersController extends GetxController {
  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final RxString searchText = ''.obs;

  Stream<List<DocumentSnapshot>> getCancelledOrdersStream() {
    final start = DateTime(
      selectedDate.value.year,
      selectedDate.value.month,
      selectedDate.value.day,
      0,
      0,
      0,
    );
    final end = DateTime(
      selectedDate.value.year,
      selectedDate.value.month,
      selectedDate.value.day,
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
        .snapshots()
        .map((snap) => snap.docs);
  }

  void setSearchText(String value) => searchText.value = value;
  void setSelectedDate(DateTime date) => selectedDate.value = date;
}

class UserCancelledOrdersPage extends StatelessWidget {
  UserCancelledOrdersPage({super.key});

  final CancelledOrdersController controller =
      Get.put(CancelledOrdersController());

  Future<void> pickDate(BuildContext context) async {
    final DateTime? newDate = await showDatePicker(
      context: context,
      initialDate: controller.selectedDate.value,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (newDate != null) controller.setSelectedDate(newDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 2, 41, 87),
        title: Text(
          "User Cancelled Orders",
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(
              children: [
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
                    onChanged: controller.setSearchText,
                  ),
                ),
                SizedBox(width: 10.w),
                Obx(() => Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        DateFormat('dd MMM yyyy')
                            .format(controller.selectedDate.value),
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )),
                SizedBox(width: 10.w),
                InkWell(
                  onTap: () => pickDate(context),
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
            child: Obx(() => StreamBuilder<List<DocumentSnapshot>>(
                  stream: controller.getCancelledOrdersStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}"));
                    }

                    final docs = snapshot.data ?? [];

                    final filtered = docs.where((doc) {
                      final order = doc.data()! as Map<String, dynamic>;
                      final tableNo =
                          (order['tableNo'] ?? '').toString().toLowerCase();
                      return tableNo.contains(
                          controller.searchText.value.toLowerCase());
                    }).toList();

                    if (filtered.isEmpty) {
                      return const Center(child: Text("No orders found"));
                    }

                    return ListView.builder(
                      padding: EdgeInsets.all(16.w),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final order = filtered[index].data() as Map<String, dynamic>;
                        final cancelledTime = order['cancelledAt'] != null
                            ? DateFormat('dd MMM yyyy hh:mm a').format(
                                (order['cancelledAt'] as Timestamp).toDate(),
                              )
                            : "N/A";

                        return Card(
                          margin: EdgeInsets.only(bottom: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          elevation: 3,
                          shadowColor: Colors.grey.shade300,
                          child: Padding(
                            padding: EdgeInsets.all(12.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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

                                // Item list
                                ...List.generate(
                                    (order['items'] as List).length, (i) {
                                  final item =
                                      (order['items'] as List)[i] as Map<String, dynamic>;
                                  return ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    leading: CachedNetworkImage(
                                      imageUrl: item['imgUrl'] ??
                                          'https://via.placeholder.com/50',
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
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if ((order['adminFeedback'] ?? '').isNotEmpty)
                                  Text(
                                    "Feedback: ${order['adminFeedback']}",
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                )),
          ),
        ],
      ),
    );
  }
}
