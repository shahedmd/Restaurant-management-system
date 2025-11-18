// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'dart:html' as html;

import 'addtransaction.dart';
import 'controller.dart';

class GBDetailsPage extends StatelessWidget {
  final String id;
  final String name;

  GBDetailsPage({super.key, required this.id, required this.name});

  final controller = Get.find<GBController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),

      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        centerTitle: true,
        backgroundColor: const Color(0xFF0C2E69),
        title: Text(name, style: TextStyle(fontSize: 18.sp, color: Colors.white,)),
        actions: [
          Padding(
            padding:  EdgeInsets.only(right: 25.w),
            child: IconButton(
              icon: const FaIcon(FontAwesomeIcons.filePdf, color: Colors.white),
              onPressed: () => downloadPDF(id, name),
            ),
          )
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0F3D85),
        onPressed: () => addTransactionDialog(controller, id),
        child: const FaIcon(FontAwesomeIcons.plus, color: Colors.white),
      ),

      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [

            /// 🌟 SUMMARY CARD
            StreamBuilder(
              stream: controller.summary(id),
              builder: (_, snap) {
                if (!snap.hasData) return const SizedBox();

                final data = snap.data!;
                return Container(
                  width: 750.w,
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F3D85), Color(0xFF0A1F44)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(2, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      summaryItem(FontAwesomeIcons.arrowDown, "Credit", data['credit']),
                      summaryItem(FontAwesomeIcons.arrowUp, "Debit", data['debit']),
                      summaryItem(FontAwesomeIcons.balanceScale, "Balance", data['balance']),
                    ],
                  ),
                );
              },
            ),

            SizedBox(height: 16.h),

            /// 🌟 TRANSACTIONS LIST
            Expanded(
              child: StreamBuilder(
                stream: controller.loadTransactions(id),
                builder: (_, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snap.data!.docs;

                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => SizedBox(height: 10.h),
                    itemBuilder: (_, i) {
                      final t = docs[i].data() as Map;

                      DateTime tDate = t["date"] is DateTime
                          ? t["date"]
                          : (t["date"] as dynamic).toDate();
                      final formattedDate = DateFormat("dd MMM yyyy").format(tDate);

                      return Padding(
                        padding:  EdgeInsets.symmetric(horizontal: 100.w, vertical: 20.h),
                        child: Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE8F1FF), Color(0xFFDCEBFF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 6,
                                offset: const Offset(2, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              FaIcon(
                                t['type'].toLowerCase() == 'credit'
                                    ? FontAwesomeIcons.arrowDown
                                    : FontAwesomeIcons.arrowUp,
                                color: Colors.blueGrey,
                                size: 18.sp,
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${t['type'].toUpperCase()} - ${t['amount']} Tk",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14.sp,
                                        color: const Color(0xFF0C2E69),
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      t['note'] ?? '',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: Colors.blueGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                formattedDate,
                                style: TextStyle(fontSize: 12.sp, color: Colors.blueGrey),
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

  /// PDF download function
  Future<void> downloadPDF(String id, String name) async {
    final snap = await controller.db
        .collection("governingBody")
        .doc(id)
        .collection("transactions")
        .orderBy("date")
        .get();

    List data = snap.docs.map((d) {
      DateTime tDate = d["date"] is DateTime ? d["date"] : (d["date"] as dynamic).toDate();
      return {
        "date": DateFormat("dd MMM yyyy").format(tDate),
        "type": d["type"],
        "amount": d["amount"],
        "note": d["note"],
      };
    }).toList();

    final pdfData = await controller.generatePDF(name, data);

    final blob = html.Blob([pdfData], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "$name-transactions.pdf")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

}

/// Summary item widget
Widget summaryItem(IconData icon, String title, dynamic value) {
  return Column(
    children: [
      FaIcon(icon, color: Colors.white, size: 20.sp),
      SizedBox(height: 4.h),
      Text(title, style: TextStyle(color: Colors.white70, fontSize: 12.sp)),
      SizedBox(height: 2.h),
      Text(value.toString(),
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.sp)),
    ],
  );
}
