// ignore_for_file: avoid_types_as_parameter_names

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'controller.dart'; // SalesController

class DailySalesPage extends StatefulWidget {
  const DailySalesPage({super.key});

  @override
  State<DailySalesPage> createState() => _DailySalesPageState();
}

class _DailySalesPageState extends State<DailySalesPage> {
  DateTime selectedDate = DateTime.now();
  final salesController = Get.put(SalesController());

  Future<void> pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String selectedId = DateFormat('yyyy-MM-dd').format(selectedDate);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection("dailySales")
          .doc(selectedId)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snap.hasData || !snap.data!.exists) {
          return Scaffold(
            appBar: AppBar(
              iconTheme: IconThemeData(color: Colors.white),
              title: Text(
                "Daily Sales - ${DateFormat('dd MMM yyyy').format(selectedDate)}",
                style: TextStyle(color: Colors.white),
              ),
              centerTitle: true,
              backgroundColor: const Color.fromARGB(255, 0, 24, 66),
              actions: [
                IconButton(
                  icon:  Icon(Icons.calendar_today, color: Colors.white,),
                  onPressed: pickDate,
                ),
              ],
            ),
            body: const Center(child: Text("No sales for selected date")),
          );
        }

        final data = snap.data!.data() as Map<String, dynamic>;
        final List orders = (data['orders'] ?? []);

        final int computedTotal = orders.fold(
          0,
          (sum, o) => sum + ((o['total'] ?? 0) as num).toInt(),
        );

        return Scaffold(
          backgroundColor: const Color(0xfff8f8f8),
          appBar: AppBar(
            title: Text(
              "Daily Sales - ${DateFormat('dd MMM yyyy').format(selectedDate)}",
              style: const TextStyle(color: Colors.white),
            ),
            centerTitle: true,
            elevation: 2,
            backgroundColor: const Color.fromARGB(255, 0, 24, 66),
            actions: [
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: pickDate,
              ),
              Obx(
                () => IconButton(
                  icon: salesController.isLoading.value
                      ? SizedBox(
                          width: 24.w,
                          height: 24.w,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const FaIcon(
                          FontAwesomeIcons.filePdf,
                          color: Colors.white,
                        ),
                  onPressed: salesController.isLoading.value || orders.isEmpty
                      ? null
                      : () async {
                          salesController.isLoading.value = true;
                          try {
                            await salesController.generateDailySalesPDF(
                              List<Map<String, dynamic>>.from(orders),
                            );
                          } finally {
                            salesController.isLoading.value = false;
                          }
                        },
                ),
              ),
            ],
          ),
          body: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==== TOTAL CARD ====
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const FaIcon(FontAwesomeIcons.sackDollar, size: 22),
                          SizedBox(width: 10.w),
                          Text(
                            "Total Sales",
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "$computedTotal৳",
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                // ==== SALE LIST ====
                Expanded(
                  child: ListView.separated(
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12.h),
                    itemBuilder: (context, index) {
                      final sale = orders[index];
                      final items = sale['items'] ?? [];
                      final time = (sale['timestamp'] as Timestamp).toDate();

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 10.h,
                          ),
                          leading: const FaIcon(FontAwesomeIcons.user),
                          title: Text(
                            sale['name'] ?? "Unknown Customer",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16.sp,
                            ),
                          ),
                          subtitle: Text(
                            "${sale['phone'] ?? 'No phone'}\n${DateFormat('hh:mm a').format(time)}",
                            style: TextStyle(fontSize: 13.sp),
                          ),
                          childrenPadding: EdgeInsets.all(12.w),
                          children: [
                            // ITEMS LIST
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: items.length,
                              itemBuilder: (_, i) {
                                final item = items[i];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(10.r),
                                    child: CachedNetworkImage(
                                      imageUrl: item['imgUrl'] ?? "",
                                      width: 55.w,
                                      height: 55.w,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) =>
                                          const CircularProgressIndicator(),
                                      errorWidget: (_, __, ___) =>
                                          const Icon(Icons.error),
                                    ),
                                  ),
                                  title: Text(
                                    item['name'] ?? "",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15.sp,
                                    ),
                                  ),
                                  subtitle: Text(
                                    "Qty: ${item['quantity']} • Price: ${item['price']}৳",
                                    style: TextStyle(fontSize: 13.sp),
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: 10.h),
                            // TOTAL ROW
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  "Total: ${sale['total']}৳",
                                  style: TextStyle(
                                    fontSize: 17.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueAccent,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8.h),
                          ],
                        ),
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
  }
}
