// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';

class GBController extends GetxController {
 final db = FirebaseFirestore.instance;

  var bodies = <Map>[].obs;

  /// Load all GB members, sorted by createdAt
  Future<void> loadBodies() async {
    final snap = await db
        .collection("governingBody")
        .orderBy("createdAt", descending: false) // first created comes first
        .get();

    bodies.value =
        snap.docs.map((d) => {"id": d.id, ...d.data()}).toList();
  }

  /// Add a new GB member
  Future<void> addBody({
    required String name,
    required String des,
    required String nid,
    required String phone,
  }) async {
    await db.collection("governingBody").add({
      "name": name,
      "des": des,
      "nid": nid,
      "phone": phone,
      "createdAt": DateTime.now(),
    });

    loadBodies(); // reload after adding
  }
  RxBool gbIsloading = false.obs;

  Future<void> addTransaction(
      String id, double amount, String note, String type, DateTime date) async {
    try {
      gbIsloading.value = true; // Start loading

      await db
          .collection("governingBody")
          .doc(id)
          .collection("transactions")
          .add({
        "amount": amount,
        "note": note,
        "type": type,
        "date": date,
      });
    } catch (e) {
      Get.snackbar("Error", e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white);
    } finally {
      gbIsloading.value = false; // Stop loading
    }
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
