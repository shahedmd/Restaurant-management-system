// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
      appBar: AppBar(
        title: Text(name),
        actions: [
          IconButton(
            icon: Icon(Icons.picture_as_pdf),
            onPressed: () => downloadPDF(id, name),
          )
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => addTransactionDialog(controller, id),
        child: Icon(Icons.add),
      ),

      body: Column(
        children: [
          // ---------------- Summary ----------------
          StreamBuilder(
            stream: controller.summary(id),
            builder: (context, snap) {
              if (!snap.hasData) return SizedBox();

              final data = snap.data!;

              return Container(
                padding: EdgeInsets.all(20),
                color: Colors.blue.shade50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Credit: ${data['credit']}"),
                    Text("Debit: ${data['debit']}"),
                    Text("Balance: ${data['balance']}"),
                  ],
                ),
              );
            },
          ),

          // ---------------- Transactions ----------------
          Expanded(
            child: StreamBuilder(
              stream: controller.loadTransactions(id),
              builder: (context, snap) {
                if (!snap.hasData) return Center(child: CircularProgressIndicator());

                final docs = snap.data!.docs;

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final t = docs[i].data() as Map;

                    return ListTile(
                      title: Text("${t['type'].toUpperCase()} - ${t['amount']}"),
                      subtitle: Text(t['note']),
                      trailing: Text(t['date'].toDate().toString().split(" ").first),
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

  // PDF DOWNLOAD FUNCTION
  Future<void> downloadPDF(String id, String name) async {
    final snap = await controller.db
        .collection("governingBody")
        .doc(id)
        .collection("transactions")
        .orderBy("date")
        .get();

    List data = snap.docs
        .map((d) => {
              "date": d["date"].toDate().toString().split(" ").first,
              "type": d["type"],
              "amount": d["amount"],
              "note": d["note"]
            })
        .toList();

    final pdfData = await controller.generatePDF(name, data);

    // Download in Web
    final blob = html.Blob([pdfData], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "$name-transaction.pdf")
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
