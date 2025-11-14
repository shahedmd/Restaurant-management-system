// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:restaurant_management/controller/printing.dart';

class Controller extends GetxController {
  Rx<Widget?> selectedPage = Rx<Widget?>(null);
  void changePage(Widget page) => selectedPage.value = page;

  final PrintingController printingController = Get.put(PrintingController());

  void showInvoiceDialog(
    BuildContext context,
    Map<String, dynamic> order,
    String docId,
  ) {
    final mobileController = TextEditingController();
    final nameController = TextEditingController();
    final discountController = TextEditingController();
    final customerName = ''.obs;
    final total = (order['total'] ?? 0).toDouble();
    final isLoading = false.obs;

    Get.dialog(
      Obx(
        () => AlertDialog(
          title: const Text('Generate Invoice'),
          content:
              isLoading.value
                  ? const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()),
                  )
                  : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Mobile
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

                            final query =
                                await FirebaseFirestore.instance
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

                        // Name
                        Obx(
                          () => TextField(
                            controller: nameController,
                            decoration: InputDecoration(
                              labelText: "Customer Name",
                              hintText:
                                  customerName.value.isEmpty
                                      ? 'Enter name'
                                      : null,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Discount
                        TextField(
                          controller: discountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Discount",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
          actions:
              isLoading.value
                  ? []
                  : [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.print, size: 18),
                      label: const Text("Generate Invoice"),
                      onPressed: () async {
                        final mobile = mobileController.text.trim();
                        final name = nameController.text.trim();

                        if (mobile.isEmpty || name.isEmpty) {
                          Get.snackbar(
                            "Error",
                            "Please enter mobile & name",
                            backgroundColor: Colors.red.shade300,
                            colorText: Colors.white,
                          );
                          return;
                        }

                        isLoading.value = true;

                        try {
                          final customerRef = FirebaseFirestore.instance
                              .collection('customers');
                          final query =
                              await customerRef
                                  .where('mobile', isEqualTo: mobile)
                                  .limit(1)
                                  .get();

                          DocumentReference docRef;
                          Map<String, dynamic> customerData;

                          // Create or fetch customer
                          if (query.docs.isNotEmpty) {
                            docRef = query.docs.first.reference;
                            customerData = query.docs.first.data();
                            customerName.value = customerData['name'] ?? name;
                          } else {
                            docRef = await customerRef.add({
                              'mobile': mobile,
                              'name': name,
                              'points': 0,
                            });
                            customerData = {
                              'mobile': mobile,
                              'name': name,
                              'points': 0,
                            };
                            customerName.value = name;
                          }

                          // Loyalty points
                          if (total >= 200) {
                            final currentPoints =
                                (customerData['points'] ?? 0) + 1;
                            await docRef.update({'points': currentPoints});
                          }

                          // Discount and total
                          final discount =
                              double.tryParse(discountController.text) ?? 0;
                          final discountedTotal = (total - discount).clamp(
                            0,
                            double.infinity,
                          );

                          // ✅ Use existing PrintingController (correct parameter order)
                          await printingController.generateInvoicePDF(
                            order,
                            discountedTotal,
                            discount,
                            {'name': customerName.value, 'mobile': mobile},
                          );

                          // Update Firestore order
                          await FirebaseFirestore.instance
                              .collection('orders')
                              .doc(docId)
                              .update({'status': 'delivered',
                              'name' : customerName.value,
                              "phone" : mobile,
                              "total" : discountedTotal
                              
                              });

                          Get.back();
                          Get.snackbar(
                            "Invoice Generated",
                            "Customer: ${customerName.value}\nTotal: BDT${discountedTotal.toStringAsFixed(2)}\nOrder marked as delivered ✅",
                            backgroundColor: Colors.green.shade400,
                            colorText: Colors.white,
                            duration: const Duration(seconds: 4),
                          );
                        } catch (e) {
                          Get.snackbar(
                            "Error",
                            e.toString(),
                            backgroundColor: Colors.red.shade400,
                            colorText: Colors.white,
                          );
                        } finally {
                          isLoading.value = false;
                        }
                      },
                    ),
                  ],
        ),
      ),
    );
  }
}
