// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:restaurant_management/controller/printing.dart';

class Controller extends GetxController {
    Rx<Widget?> selectedPage = Rx<Widget?>(null);


  void changePage(Widget page) {
    selectedPage.value = page;
  }


final PrintingController  printingController = Get.put(PrintingController());

void showInvoiceDialog(BuildContext context, Map<String, dynamic> order, String docId) {
    final mobileController = TextEditingController();
    final nameController = TextEditingController();
    final discountController = TextEditingController();
    final customerName = ''.obs;
    final total = (order['total'] ?? 0).toDouble();

    Get.dialog(
      AlertDialog(
        title: const Text('Generate Invoice'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: mobileController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Customer Mobile",
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) async {
                  final mobile = val.trim();
                  if (mobile.isEmpty) return;

                  final query = await FirebaseFirestore.instance
                      .collection('customers')
                      .where('mobile', isEqualTo: mobile)
                      .limit(1)
                      .get();

                  if (query.docs.isNotEmpty) {
                    final data = query.docs.first.data();
                    customerName.value = data['name'] ?? '';
                    nameController.text = customerName.value;
                  } else {
                    customerName.value = '';
                    nameController.text = '';
                  }
                },
              ),
              const SizedBox(height: 10),
              Obx(() => TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: "Customer Name",
                      hintText: customerName.value.isEmpty ? 'Enter name' : null,
                      border: const OutlineInputBorder(),
                    ),
                  )),
              const SizedBox(height: 10),
              TextField(
                controller: discountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Discount (৳)",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
          ElevatedButton.icon(
            icon: const Icon(Icons.print, size: 18),
            label: const Text("Generate Invoice"),
            onPressed: () async {
              final mobile = mobileController.text.trim();
              final name = nameController.text.trim();

              if (mobile.isEmpty || name.isEmpty) {
                Get.snackbar("Error", "Please enter mobile & name",
                    backgroundColor: Colors.red.shade300, colorText: Colors.white);
                return;
              }

              final customerRef = FirebaseFirestore.instance.collection('customers');
              final query = await customerRef.where('mobile', isEqualTo: mobile).limit(1).get();

              DocumentReference docRef;
              Map<String, dynamic> customerData;

              if (query.docs.isNotEmpty) {
                docRef = query.docs.first.reference;
                customerData = query.docs.first.data();
                customerName.value = customerData['name'] ?? name;
              } else {
                docRef = await customerRef.add({'mobile': mobile, 'name': name, 'points': 0});
                customerData = {'mobile': mobile, 'name': name, 'points': 0};
                customerName.value = name;
              }

              // Loyalty points
              if (total >= 200) {
                final currentPoints = (customerData['points'] ?? 0) + 1;
                await docRef.update({'points': currentPoints});
              }

              final discount = double.tryParse(discountController.text) ?? 0;
              final discountedTotal = (total - discount).clamp(0, double.infinity);

              // Generate PDF using default font
              final pdf = pw.Document();
              final date = DateTime.now();
              final formattedDate = "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2,'0')}";

              pdf.addPage(
                pw.MultiPage(
                  build: (context) => [
                    pw.Center(
                        child: pw.Text("Blue Bite Restaurant",
                            style:  pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold))),
                    pw.Center(child: pw.Text("Madaripur Sadar, Beside Lake (Selfie Tower)")),
                    pw.SizedBox(height: 10),
                    pw.Text("Customer: ${customerName.value}"),
                    pw.Text("Mobile: $mobile"),
                    pw.Text("Order Time: $formattedDate"),
                    pw.Divider(),
                    ...List<pw.Widget>.from((order['items'] as List<dynamic>).map((item) => pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text("${item['name']} ×${item['quantity']}"),
                            pw.Text("৳${item['price']}"),
                          ],
                        ))),
                    pw.Divider(),
                    pw.Text("Discount: ৳$discount"),
                    pw.Text("Total: ৳$discountedTotal", style:  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 20),
                    pw.Center(child: pw.Text("Thank you for dining with Blue Bite Restaurant!")),
                    pw.Center(child: pw.Text("We hope to serve you again!")),
                  ],
                ),
              );

              // Save PDF for Web
              final pdfBytes = await pdf.save();
              final blob = html.Blob([pdfBytes], 'application/pdf');
              final url = html.Url.createObjectUrlFromBlob(blob);
              html.window.open(url, '_blank');

              // Update order status
              await FirebaseFirestore.instance.collection('orders').doc(docId).update({'status': 'delivered'});

              Get.back();
              Get.snackbar("Invoice Generated",
                  "Customer: ${customerName.value}\nTotal: ৳$discountedTotal\nOrder marked as delivered ✅",
                  backgroundColor: Colors.green.shade400,
                  colorText: Colors.white,
                  duration: const Duration(seconds: 4));
            },
          ),
        ],
      ),
    );
  }



  
}



