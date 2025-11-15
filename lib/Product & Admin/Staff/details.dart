// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controller.dart';
import 'dart:html' as html;

import 'transaction.dart';

class StaffDetailsPage extends StatelessWidget {
  final String staffId;
  final String name;

  StaffDetailsPage({required this.staffId, required this.name});

  final controller = Get.find<StaffController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
          IconButton(
            icon: Icon(Icons.picture_as_pdf),
            onPressed: () => downloadStaffPDF(),
          )
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => addSalaryDialog(controller, staffId),
        child: Icon(Icons.add),
      ),

      body: Column(
        children: [
          // Salary Summary
          StreamBuilder(
            stream: controller.totalSalary(staffId),
            builder: (_, snap) {
              if (!snap.hasData) return SizedBox();
              return Container(
                padding: EdgeInsets.all(20),
                color: Colors.green.shade50,
                child: Text(
                  "Total Paid Salary: ${snap.data}",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              );
            },
          ),

          // Salary List
          Expanded(
            child: StreamBuilder(
              stream: controller.loadSalaries(staffId),
              builder: (_, snap) {
                if (!snap.hasData) return Center(child: CircularProgressIndicator());

                final docs = snap.data!.docs;

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final s = docs[i].data() as Map;

                    return ListTile(
                      title: Text("${s['month']} - ${s['amount']}"),
                      subtitle: Text(s["note"]),
                      trailing: Text(s["date"].toDate().toString().split(" ").first),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }

  // PDF download
  Future<void> downloadStaffPDF() async {
    final snap = await controller.db
        .collection("staff")
        .doc(staffId)
        .collection("salaries")
        .get();

    List salaryList = snap.docs.map((d) {
      return {
        "month": d["month"],
        "amount": d["amount"],
        "note": d["note"],
        "date": d["date"].toDate().toString().split(" ").first,
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
