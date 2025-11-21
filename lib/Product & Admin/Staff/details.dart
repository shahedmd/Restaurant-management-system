// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:restaurant_management/Product%20&%20Admin/Staff/transaction.dart';
import 'dart:html' as html;

import 'controller.dart';

class StaffDetailsPage extends StatelessWidget {
  final String staffId;
  final String name;

  StaffDetailsPage({super.key, required this.staffId, required this.name});

  final controller = Get.find<StaffController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // light background

      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Color(0xFF0C2E69),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          name,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          Padding(
            padding:  EdgeInsets.only(right: 20.w),
            child: IconButton(
              icon: const FaIcon(FontAwesomeIcons.filePdf, color: Colors.white),
              onPressed: () => downloadStaffPDF(),
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        onPressed: () => addSalaryDialog(controller, staffId,  name),
        child: const FaIcon(FontAwesomeIcons.plus, color: Colors.white),
      ),

      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [

            /// Salary Summary Card
            StreamBuilder(
              stream: controller.totalSalary(staffId),
              builder: (_, snap) {
                if (!snap.hasData) return const SizedBox();
                return Container(
                  width: 400.w,
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(2, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const FaIcon(FontAwesomeIcons.wallet, color: Colors.blueAccent),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          "Total Paid Salary: ${snap.data} Tk",
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            SizedBox(height: 16.h),

            /// Salary List
            Expanded(
              child: StreamBuilder(
                stream: controller.loadSalaries(staffId),
                builder: (_, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
            
                  final docs = snap.data!.docs;
            
                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => SizedBox(height: 10.h),
                    itemBuilder: (_, i) {
                      final s = docs[i].data() as Map;
            
                      DateTime salaryDate = s["date"] is DateTime
                          ? s["date"]
                          : (s["date"] as dynamic).toDate();
            
                      final formattedDate =
                          DateFormat("dd MMM yyyy").format(salaryDate);
            
                      return Padding(
                        padding:  EdgeInsets.symmetric(horizontal: 100.w),
                        child: Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                                offset: const Offset(2, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const FaIcon(FontAwesomeIcons.coins,
                                  color: Colors.blueAccent, size: 18),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${s['month']} - ${s['amount']} Tk",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14.sp,
                                          color: Colors.black87),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      s["note"] ?? "",
                                      style: TextStyle(
                                          fontSize: 12.sp, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                formattedDate,
                                style: TextStyle(
                                    fontSize: 12.sp, color: Colors.blue.shade800),
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
      ),
    );
  }

  /// PDF download
  Future<void> downloadStaffPDF() async {
    final snap = await controller.db
        .collection("staff")
        .doc(staffId)
        .collection("salaries")
        .get();

    List salaryList = snap.docs.map((d) {
      DateTime date = d["date"] is DateTime
          ? d["date"]
          : (d["date"] as dynamic).toDate();

      return {
        "month": d["month"],
        "amount": d["amount"],
        "note": d["note"],
        "date": DateFormat("dd MMM yyyy").format(date),
      };
    }).toList();

    final pdfData = await controller.generatePDF(name, salaryList);

    final blob = html.Blob([pdfData], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "$name-salary.pdf")
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
