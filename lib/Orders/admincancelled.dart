// ignore_for_file: avoid_print, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AdminCancelledOrdersPage extends StatefulWidget {
  const AdminCancelledOrdersPage({super.key});

  @override
  State<AdminCancelledOrdersPage> createState() =>
      _AdminCancelledOrdersPageState();
}

class _AdminCancelledOrdersPageState extends State<AdminCancelledOrdersPage> {
  String searchText = "";
  DateTime selectedDate = DateTime.now();

  Future<void> pickDate() async {
    final DateTime? newDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (newDate != null) {
      setState(() {
        selectedDate = newDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildFilterRow(),
          Expanded(child: _buildCancelledOrdersStream()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color.fromARGB(255, 2, 41, 87),
      elevation: 1,
      title: const Text(
        "Admin Cancelled Orders",
        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
      ),
      centerTitle: true,
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }

  Widget _buildFilterRow() {
    return Padding(
      padding: EdgeInsets.all(12.w),
      child: Row(
        children: [
          // Search Field
          Expanded(
            child: TextField(
              keyboardType: TextInputType.number,
              onChanged: (v) {
                setState(() {
                  searchText = v.trim();
                });
              },
              decoration: InputDecoration(
                hintText: "Search by Table No...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          // Selected Date Display
          InkWell(
            onTap: pickDate,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                DateFormat('dd MMM yyyy').format(selectedDate),
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          // Calendar Button
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
    );
  }

  Widget _buildCancelledOrdersStream() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("orders")
          .where("status", isEqualTo: "cancelled")
          .orderBy("timestamp", descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data!.docs;

        // Filter by selected date
        final filteredByDate = docs.where((d) {
          final Timestamp ts = d['timestamp'];
          final DateTime dt = ts.toDate();
          return dt.year == selectedDate.year &&
              dt.month == selectedDate.month &&
              dt.day == selectedDate.day;
        }).toList();

        // Filter by search text
        final filtered = filteredByDate.where((d) {
          final tableNo = (d['tableNo'] ?? "").toString();
          return tableNo.contains(searchText);
        }).toList();

        if (filtered.isEmpty) {
          return const Center(
            child: Text(
              "No Cancelled Orders Found",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            return _buildCancelledOrderCard(filtered[index]);
          },
        );
      },
    );
  }

  Widget _buildCancelledOrderCard(DocumentSnapshot data) {
    final Timestamp time = data['timestamp'];
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(time.toDate());

    final items = List.from(data['items'] ?? []);
    final firstItem = items.isNotEmpty ? items[0] : null;

    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14.r),
            child: CachedNetworkImage(
              imageUrl: firstItem?['imgUrl'] ?? "",
              width: 85.w,
              height: 85.w,
              fit: BoxFit.cover,
              errorWidget: (c, u, e) =>
                  const Icon(Icons.broken_image, size: 40),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Cancellation: ${data['adminFeedback'] ?? "Unknown Reason"}",
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  firstItem?['name'] ?? "Unknown Item",
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4.h),
                Text("Table No: ${data['tableNo']}"),
                Text("Amount: ${data['total']} TK"),
                SizedBox(height: 6.h),
                Row(
                  children: [
                    FaIcon(
                      data['orderType'] == "Prebooking"
                          ? FontAwesomeIcons.clock
                          : FontAwesomeIcons.utensils,
                      size: 14.sp,
                      color: Colors.red,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      data['orderType'] == "Prebooking"
                          ? "Prebook"
                          : "Inhouse",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                        fontSize: 13.sp,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              "Cancelled",
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w700,
                fontSize: 13.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
