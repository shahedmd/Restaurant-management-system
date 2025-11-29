// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class TodayOverviewController extends GetxController {
  final RxDouble dailySales = 0.0.obs;
  final RxDouble dailyExpenses = 0.0.obs;
  final RxDouble dailyCash = 0.0.obs;

  final RxInt dailyCustomers = 0.obs;

  final RxInt customerCancelledOrders = 0.obs;
  final RxInt adminCancelledOrders = 0.obs;

  final RxInt deliveredOrdersToday = 0.obs;
  final RxInt pendingOrdersToday = 0.obs;
  final RxInt processingOrdersToday = 0.obs;

  final RxList<Map<String, dynamic>> last3DeliveredOrders =
      <Map<String, dynamic>>[].obs;

  final DateFormat dateFormat = DateFormat('yyyy-MM-dd');

  final ordersRef = FirebaseFirestore.instance.collection('orders');
  final cancelledRef = FirebaseFirestore.instance.collection('cancelledOrders');
  final dailyExpensesRef = FirebaseFirestore.instance.collection('daily_expenses');

  void fetchOverview() async {
    final todayStr = dateFormat.format(DateTime.now());

    // ---------------------------------------------------------
    // FETCH TODAY ORDERS
    // ---------------------------------------------------------
    final ordersSnap = await ordersRef.get();

    double sales = 0.0;
    final Set<String> customers = {};
    final List<Map<String, dynamic>> todayDeliveredOrders = [];

    int deliveredCount = 0;
    int pendingCount = 0;
    int processingCount = 0;
    int adminCancelled = 0;

    for (var doc in ordersSnap.docs) {
      final data = doc.data();
      final ts = data['timestamp'] as Timestamp?;
      if (ts == null) continue;

      final dateStr = dateFormat.format(ts.toDate());
      if (dateStr != todayStr) continue;

      String status = (data['status'] ?? "").toString().toLowerCase();

      // Count status types
      if (status == 'delivered') {
        deliveredCount++;
        sales += (data['total'] as num?)?.toDouble() ?? 0.0;

        // Add delivered orders to last3DeliveredOrders
        todayDeliveredOrders.add({
          'tableNo': data['tableNo'] ?? 'N/A',
          'total': data['total'] ?? 0,
          'orderType': data['orderType'] ?? 'N/A',
          'timestamp': ts.toDate(),
        });
      }

      if (status == 'pending') pendingCount++;
      if (status == 'processing') processingCount++;
      if (status == 'cancelled') adminCancelled++;

      // Unique customers
      final phone = data['phone']?.toString() ?? "";
      if (phone.isNotEmpty) customers.add(phone);
    }

    // Sort descending (newest first)
    todayDeliveredOrders.sort((a, b) =>
        (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));

    last3DeliveredOrders.value = todayDeliveredOrders.take(3).toList();

    // Update GetX values
    dailySales.value = sales;
    dailyCustomers.value = customers.length;

    deliveredOrdersToday.value = deliveredCount;
    pendingOrdersToday.value = pendingCount;
    processingOrdersToday.value = processingCount;
    adminCancelledOrders.value = adminCancelled;

    // ---------------------------------------------------------
    // CUSTOMER CANCELLED (cancelledOrders collection)
    // ---------------------------------------------------------
    final cancelledSnap = await cancelledRef.get();
    int customerCancelled = 0;

    for (var doc in cancelledSnap.docs) {
      final data = doc.data();
      final ts = data['timestamp'] as Timestamp?;
      if (ts == null) continue;

      final dateStr = dateFormat.format(ts.toDate());
      if (dateStr == todayStr) {
        if ((data['cancelledByUser'] ?? true) == true) {
          customerCancelled++;
        }
      }
    }

    customerCancelledOrders.value = customerCancelled;

    // ---------------------------------------------------------
    // DAILY EXPENSES
    // ---------------------------------------------------------
    double expenses = 0.0;
    final todayDocRef = dailyExpensesRef.doc(todayStr);
    final itemsSnap = await todayDocRef.collection('items').get();

    for (var doc in itemsSnap.docs) {
      expenses += (doc.data()['amount'] as num?)?.toDouble() ?? 0.0;
    }

    dailyExpenses.value = expenses;
    dailyCash.value = sales - expenses;
  }
}

class TodayOverviewPage extends StatelessWidget {
  TodayOverviewPage({super.key});

  final TodayOverviewController controller = Get.put(TodayOverviewController());
  final DateFormat displayFormat = DateFormat('hh:mm a');

  @override
  Widget build(BuildContext context) {
    controller.fetchOverview();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Today's Overview",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 2, 41, 87),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Obx(() {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 16.w,
                runSpacing: 16.h,
                children: [
                  _overviewCard(
                    "Daily Sales",
                    "৳${controller.dailySales.value.toStringAsFixed(2)}",
                    [Colors.blue.shade400, Colors.blue.shade700],
                    FontAwesomeIcons.moneyBillWave,
                  ),
                  _overviewCard(
                    "Daily Expenses",
                    "৳${controller.dailyExpenses.value.toStringAsFixed(2)}",
                    [Colors.red.shade400, Colors.red.shade700],
                    FontAwesomeIcons.moneyCheckDollar,
                  ),
                  _overviewCard(
                    "Daily Cash",
                    "৳${controller.dailyCash.value.toStringAsFixed(2)}",
                    [Colors.green.shade400, Colors.green.shade700],
                    FontAwesomeIcons.cashRegister,
                  ),
                  _overviewCard(
                    "Customers Today",
                    controller.dailyCustomers.value.toString(),
                    [Colors.purple.shade400, Colors.purple.shade700],
                    FontAwesomeIcons.users,
                  ),
                  _overviewCard(
                    "Delivered Orders",
                    controller.deliveredOrdersToday.value.toString(),
                    [Colors.greenAccent.shade400, Colors.green.shade700],
                    FontAwesomeIcons.checkCircle,
                  ),
                  _overviewCard(
                    "Pending Orders",
                    controller.pendingOrdersToday.value.toString(),
                    [Colors.deepPurpleAccent.shade200, Colors.deepPurple.shade700],
                    FontAwesomeIcons.clock,
                  ),
                  _overviewCard(
                    "Processing Orders",
                    controller.processingOrdersToday.value.toString(),
                    [Colors.blueGrey.shade400, Colors.blueGrey.shade700],
                    FontAwesomeIcons.gear,
                  ),
                  _overviewCard(
                    "Customer Cancelled",
                    controller.customerCancelledOrders.value.toString(),
                    [Colors.orange.shade400, Colors.orange.shade700],
                    FontAwesomeIcons.userSlash,
                  ),
                  _overviewCard(
                    "Admin Cancelled",
                    controller.adminCancelledOrders.value.toString(),
                    [Colors.teal.shade400, Colors.teal.shade700],
                    FontAwesomeIcons.userShield,
                  ),
                ],
              ),

              SizedBox(height: 24.h),

              Text(
                "Last 3 Delivered Orders Today",
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.h),

              Column(
                children: List.generate(controller.last3DeliveredOrders.length, (index) {
                  final order = controller.last3DeliveredOrders[index];
                  final serial = index + 1;

                  return Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    margin: EdgeInsets.symmetric(vertical: 8.h),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                      leading: CircleAvatar(
                        radius: 24.r,
                        backgroundColor: Colors.blue.shade100,
                        child: Text(
                          serial.toString(),
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
                        ),
                      ),
                      title: Text(
                        "Table: ${order['tableNo']} • ${order['orderType']}",
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        "Total: ৳${order['total']} • ${displayFormat.format(order['timestamp'])}",
                        style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _overviewCard(
      String title, String value, List<Color> gradientColors, IconData icon) {
    return Container(
      width: 180.w,
      height: 250.h,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FaIcon(icon, size: 30.sp, color: Colors.white),
          SizedBox(height: 16.h),
          Text(
            title,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
