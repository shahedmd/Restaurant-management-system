// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';

class GBController extends GetxController {
  FirebaseFirestore db = FirebaseFirestore.instance;

  var bodies = [].obs;

  Future<void> loadBodies() async {
    final snap = await db.collection("governingBody").get();
    bodies.value = snap.docs.map((d) => {"id": d.id, ...d.data()}).toList();
  }

  Future<void> addBody(String name, String phone) async {
    await db.collection("governingBody").add({
      "name": name,
      "phone": phone,
      "createdAt": DateTime.now(),
    });

    loadBodies();
  }

  Future<void> addTransaction(
      String id, double amount, String note, String type) async {
    await db
        .collection("governingBody")
        .doc(id)
        .collection("transactions")
        .add({
      "amount": amount,
      "note": note,
      "type": type,
      "date": DateTime.now(),
    });
  }

  Stream<QuerySnapshot> loadTransactions(String id) {
    return db
        .collection("governingBody")
        .doc(id)
        .collection("transactions")
        .orderBy("date", descending: true)
        .snapshots();
  }

  Stream<Map<String, dynamic>> summary(String id) {
    return loadTransactions(id).map((snap) {
      double credit = 0;
      double debit = 0;

      for (var doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data["type"] == "credit") credit += data["amount"];
        if (data["type"] == "debit") debit += data["amount"];
      }

      return {
        "credit": credit,
        "debit": debit,
        "balance": credit - debit,
      };
    });
  }

  // =============================
  // PDF GENERATOR
  // =============================
  Future<Uint8List> generatePDF(String name, List transactions) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("Governing Body: $name",
                  style: pw.TextStyle(fontSize: 22)),
              pw.SizedBox(height: 15),

              pw.Text("Transaction History",
                  style: pw.TextStyle(fontSize: 16)),
              pw.SizedBox(height: 10),

              pw.Table.fromTextArray(
                headers: ["Date", "Type", "Amount", "Note"],
                data: transactions
                    .map((t) => [
                          t["date"],
                          t["type"],
                          t["amount"].toString(),
                          t["note"]
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
