// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../controller/menucontroller.dart';

class DeliveredOrdersPage extends StatefulWidget {
  const DeliveredOrdersPage({super.key});

  @override
  State<DeliveredOrdersPage> createState() => _DeliveredOrdersPageState();
}

class _DeliveredOrdersPageState extends State<DeliveredOrdersPage> {
  final Controller controller = Get.put(Controller());

  DateTime selectedDate = DateTime.now();
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final startOfDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    final endOfDay = startOfDay.add(const Duration(days: 1));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 2, 41, 87),
        centerTitle: true,
        title: const Text(
          "Delivered Orders",
          style: TextStyle(color: Colors.white),
        ),
      ),

      body: Column(
        children: [
          // 🔍 Search Bar + Date Picker
          Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Search by name or phone",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() => searchQuery = value.trim());
                    },
                  ),
                ),
                SizedBox(width: 10.w),

                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    DateFormat('dd MMM yyyy').format(selectedDate),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                SizedBox(width: 10.w),

                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );

                    if (picked != null) {
                      setState(() => selectedDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.calendar_month,
                        color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('status', isEqualTo: 'delivered')
                  .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
                  .where('timestamp', isLessThan: endOfDay)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),

              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filtered = snapshot.data!.docs.where((doc) {
                  final data = doc.data()! as Map<String, dynamic>;
                  return data['name']
                          .toString()
                          .toLowerCase()
                          .contains(searchQuery.toLowerCase()) ||
                      data['phone']
                          .toString()
                          .toLowerCase()
                          .contains(searchQuery.toLowerCase());
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text("No delivered orders found"));
                }

                return ListView.builder(
                  padding: EdgeInsets.all(12.w),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final order =
                        filtered[index].data()! as Map<String, dynamic>;

                    final timestamp = order['timestamp'] as Timestamp?;
                    final orderTime = timestamp != null
                        ? DateFormat('dd MMM yyyy hh:mm a')
                            .format(timestamp.toDate())
                        : 'N/A';

                    final manualDiscount =
                        (order['manualDiscount'] ?? 0).toDouble();
                    final pointsUsed = (order['pointsUsed'] ?? 0).toDouble();
                    final totalDiscount = manualDiscount + pointsUsed;
                    final discountedTotal =
                        (order['total'] - totalDiscount).clamp(0.0, 999999.0);

                    return Padding(
                      padding: EdgeInsets.only(bottom: 15.h),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        elevation: 3,
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.all(12.w),

                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                order['name'],
                                style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "BDT $discountedTotal",
                                style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),

                          subtitle: Text(
                            "${order['phone']} • $orderTime",
                            style: TextStyle(fontSize: 13.sp),
                          ),

                          children: [
                            Padding(
                              padding: EdgeInsets.all(12.w),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Order Type: ${order['orderType']}"),
                                  Text("Table: ${order['tableNo']}"),

                                  if (order['prebookSlot'] != null)
                                    Text(
                                      "Prebooking: ${DateFormat('dd MMM yyyy, hh:mm a').format((order['prebookSlot'] as Timestamp).toDate())}",
                                    ),

                                  if ((order['adminFeedback'] ?? '')
                                      .toString()
                                      .isNotEmpty)
                                    Text("Feedback: ${order['adminFeedback']}"),

                                  Divider(height: 20.h),

                                  Text("Items:",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),

                                  ...List.generate(
                                      (order['items'] as List).length, (i) {
                                    final item = (order['items'] as List)[i]
                                        as Map<String, dynamic>;

                                    final price = item['price'] ??
                                        item['selectedVariant']?['price'] ??
                                        0;

                                    final variantSize =
                                        item['selectedVariant']?['size'];

                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: item['imgUrl'] != null
                                          ? CachedNetworkImage(
                                              imageUrl: item['imgUrl'],
                                              width: 50.w,
                                              height: 50.h,
                                              fit: BoxFit.cover,
                                            )
                                          : Icon(FontAwesomeIcons.burger,
                                              size: 22.sp),
                                      title: Text(
                                          "${item['name']} ×${item['quantity']}"),
                                      subtitle: Text(
                                          "Category: ${item['category']}"
                                          "${variantSize != null ? ' | Size: $variantSize' : ''}"),
                                      trailing: Text("BDT $price"),
                                    );
                                  }),

                                  Divider(),

                                  Text("Manual Discount: BDT $manualDiscount"),
                                  Text("Points Used: BDT $pointsUsed"),
                                  Text("Total Payable: BDT $discountedTotal"),
                                  Text(
                                      "Points Remaining: ${order['pointsRemaining']}"),
                                  Text(
                                      "Points Earned: ${order['pointsEarned']}"),

                                  SizedBox(height: 10.h),

                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton.icon(
                                      icon: FaIcon(FontAwesomeIcons.download,
                                          size: 18.sp),
                                      label: Text("Generate Invoice"),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.greenAccent),
                                      onPressed: () async {
                                        await controller.printingController
                                            .generateInvoicePDF(
                                          order,
                                          discountedTotal,
                                          totalDiscount,
                                          {
                                            'name': order['name'],
                                            'mobile': order['phone'],
                                          },
                                          {
                                            'pointsUsed':
                                                order['pointsUsed'] ?? 0,
                                            'pointsEarned':
                                                order['pointsEarned'] ?? 0,
                                            'pointsRemaining':
                                                order['pointsRemaining'] ?? 0,
                                            'originalPoints':
                                                order['previousPoint'],
                                          },
                                        );
                                      },
                                    ),
                                  )
                                ],
                              ),
                            )
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
