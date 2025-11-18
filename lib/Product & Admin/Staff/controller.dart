// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';

class StaffController extends GetxController {
 
@override
void onInit() {
  super.onInit();
  loadStaff();
}

  FirebaseFirestore db = FirebaseFirestore.instance;

  var staffList = [].obs;

  Future<void> loadStaff() async {
    final snap = await db.collection("staff")
    .orderBy("createdAt", descending: false)
    .get();
    staffList.value =
        snap.docs.map((d) => {"id": d.id, ...d.data()}).toList();
  }

Future<void> addStaff({
  required String name,
  required String phone,
  required String nid,
  required String des,
  required int salary,
  required DateTime joinDate,
}) async {
  await db.collection("staff").add({
    "name": name,
    "phone": phone,
    "nid": nid,
    "des": des,
    "salary": salary,
    "joiningDate": joinDate,
    "createdAt": DateTime.now(),
  });

  loadStaff();
}


Future<void> addSalary(
    String staffId, double amount, String note, String month, DateTime date) async {
  await db.collection("staff").doc(staffId).collection("salaries").add({
    "amount": amount,
    "note": note,
    "month": month,
    "date": date,
  });
}

  Stream<QuerySnapshot> loadSalaries(String staffId) {
    return db
        .collection("staff")
        .doc(staffId)
        .collection("salaries")
        .orderBy("date", descending: true)
        .snapshots();
  }

  Stream<double> totalSalary(String staffId) {
    return loadSalaries(staffId).map((snap) {
      double total = 0;
      for (var doc in snap.docs) {
        total += doc["amount"];
      }
      return total;
    });
  }

  // PDF Generator
  Future<Uint8List> generatePDF(String name, List salaries) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("Staff Salary Report: $name",
                  style: pw.TextStyle(fontSize: 22)),
              pw.SizedBox(height: 15),
              pw.Table.fromTextArray(
                headers: ["Month", "Amount", "Note", "Date"],
                data: salaries
                    .map((s) => [
                          s["month"],
                          s["amount"].toString(),
                          s["note"],
                          s["date"],
                        ])
                    .toList(),
              )
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}
