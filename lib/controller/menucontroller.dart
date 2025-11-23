// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:restaurant_management/controller/printing.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class Controller extends GetxController {
  Rx<Widget?> selectedPage = Rx<Widget?>(null);
  void changePage(Widget page) => selectedPage.value = page;

  final PrintingController printingController = Get.put(PrintingController());

  /// Show invoice dialog with points usage feature
 Future<bool> showInvoiceDialog(
    BuildContext context,
    Map<String, dynamic> order,
    String docId,
  ) {
    final TextEditingController mobileController = TextEditingController(
      text: order['phone']?.toString() ?? '',
    );
    final TextEditingController nameController = TextEditingController(
      text: order['name']?.toString() ?? '',
    );
    final TextEditingController discountController = TextEditingController();
    final TextEditingController pointsToUseController = TextEditingController();

    final RxString customerName = ''.obs;
    final RxInt customerPoints = 0.obs; // fetched from firestore
    final RxBool isLoading = false.obs;
    final RxBool pointsAllowed =
        false.obs; // whether user can use points (>100)
    final RxDouble computedTotal = RxDouble(
      ((order['total'] ?? 0) as num).toDouble(),
    );

    final double originalTotal = ((order['total'] ?? 0) as num).toDouble();
    // For displaying friendly dates if needed inside PDF
    final completer = Completer<bool>();


    // Helper: fetch customer by mobile (if exists) and set points
    Future<void> fetchCustomerByMobile(String mobile) async {
      if (mobile.isEmpty) {
        customerName.value = '';
        customerPoints.value = 0;
        pointsAllowed.value = false;
        return;
      }

      try {
        final q =
            await FirebaseFirestore.instance
                .collection('customers')
                .where('mobile', isEqualTo: mobile)
                .limit(1)
                .get();

        if (q.docs.isNotEmpty) {
          final data = q.docs.first.data();
          customerName.value = (data['name'] ?? '') as String;
          customerPoints.value = ((data['points'] ?? 0) as num).toInt();
          pointsAllowed.value = customerPoints.value > 100;
          nameController.text =
              customerName.value.isNotEmpty
                  ? customerName.value
                  : nameController.text;
        } else {
          // no customer found
          customerName.value = '';
          customerPoints.value = 0;
          pointsAllowed.value = false;
        }
      } catch (e) {
        customerName.value = '';
        customerPoints.value = 0;
        pointsAllowed.value = false;
        debugPrint('Error fetching customer: $e');
      }
    }

    // Initialize by trying to fetch existing customer from order phone (if provided)
    final initialMobile = mobileController.text.trim();
    if (initialMobile.isNotEmpty) {
      fetchCustomerByMobile(initialMobile);
    }

    Get.dialog(
      Obx(
        () => AlertDialog(
          title: const Text('Generate Invoice'),
          content:
              isLoading.value
                  ? SizedBox(
                    height: 110.h,
                    child: const Center(child: CircularProgressIndicator()),
                  )
                  : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Mobile
                        TextField(
                          controller: mobileController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: "Customer Mobile",
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: FaIcon(
                                FontAwesomeIcons.search,
                                size: 16.sp,
                              ),
                              onPressed: () {
                                fetchCustomerByMobile(
                                  mobileController.text.trim(),
                                );
                              },
                            ),
                          ),
                          onChanged: (val) {
                            // debounce-like behavior: call fetch only for non-empty values
                            final mobile = val.trim();
                            if (mobile.isEmpty) {
                              customerName.value = '';
                              customerPoints.value = 0;
                              pointsAllowed.value = false;
                            } else {
                              // fetch customer details
                              fetchCustomerByMobile(mobile);
                            }
                          },
                        ),
                        SizedBox(height: 10.h),

                        // Name
                        TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            labelText: "Customer Name",
                            border: const OutlineInputBorder(),
                            hintText:
                                customerName.value.isEmpty
                                    ? 'Enter name'
                                    : null,
                          ),
                        ),
                        SizedBox(height: 10.h),

                        // Show fetched points (read-only)
                        TextField(
                          controller: TextEditingController(
                            text: customerPoints.value.toString(),
                          ),
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: "Customer Points (available)",
                            border: const OutlineInputBorder(),
                            helperText:
                                pointsAllowed.value
                                    ? 'Points can be used as discount (1 point = 1 BDT). Minimum to use: >100.'
                                    : 'Customer needs >100 points to be eligible to use points.',
                          ),
                        ),
                        SizedBox(height: 10.h),

                        // Points to use input (only enabled if eligible)
                        TextField(
                          controller: pointsToUseController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "Points to Use (BDT)",
                            border: const OutlineInputBorder(),
                            helperText:
                                pointsAllowed.value
                                    ? 'Max ${customerPoints.value}'
                                    : 'Not eligible to use points',
                          ),
                          enabled: pointsAllowed.value,
                          onChanged: (val) {
                            // sanitize input and ensure not exceeding available points
                            final parsed = int.tryParse(val) ?? 0;
                            if (parsed > customerPoints.value) {
                              pointsToUseController.text =
                                  customerPoints.value.toString();
                              pointsToUseController
                                  .selection = TextSelection.fromPosition(
                                TextPosition(
                                  offset: pointsToUseController.text.length,
                                ),
                              );
                            }
                          },
                        ),
                        SizedBox(height: 10.h),

                        // Manual Discount (admin)
                        TextField(
                          controller: discountController,
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: "Manual Discount (BDT)",
                            border: OutlineInputBorder(),
                            helperText:
                                'Optional extra discount (applied before points).',
                          ),
                        ),

                        SizedBox(height: 12.h),

                        // Show calculation summary preview (reactive-ish)
                        Builder(
                          builder: (_) {
                            final manualDiscount =
                                double.tryParse(discountController.text) ?? 0.0;
                            final pointsUsed =
                                int.tryParse(pointsToUseController.text) ?? 0;
                            final totalDiscount = (manualDiscount + pointsUsed)
                                .clamp(0.0, originalTotal);
                            final finalTotal = (originalTotal - totalDiscount)
                                .clamp(0.0, double.infinity);
                            // update computedTotal for dialog usage
                            computedTotal.value = finalTotal;

                            return Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(12.h),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Original Total: BDT ${originalTotal.toStringAsFixed(2)}",
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 6.h),
                                  Text(
                                    "Manual Discount: BDT ${manualDiscount.toStringAsFixed(2)}",
                                    style: TextStyle(fontSize: 12.sp),
                                  ),
                                  SizedBox(height: 6.h),
                                  Text(
                                    "Points Used as Discount: BDT ${pointsUsed.toString()}",
                                    style: TextStyle(fontSize: 12.sp),
                                  ),
                                  SizedBox(height: 8.h),
                                  Divider(),
                                  SizedBox(height: 6.h),
                                  Text(
                                    "Final Total: BDT ${finalTotal.toStringAsFixed(2)}",
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
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

                        // Begin processing
                        isLoading.value = true;

                        try {
                          // Fetch or create customer doc
                          final customerRef = FirebaseFirestore.instance
                              .collection('customers');
                          final query =
                              await customerRef
                                  .where('mobile', isEqualTo: mobile)
                                  .limit(1)
                                  .get();

                          DocumentReference custDocRef;

                          if (query.docs.isNotEmpty) {
                            custDocRef = query.docs.first.reference;
                          } else {
                            custDocRef = await customerRef.add({
                              'mobile': mobile,
                              'name': name,
                              'points': 0,
                            });
                          }

                          // Re-read fresh points to avoid race conditions
                          final freshSnapshot = await custDocRef.get();
                          final freshData =
                              freshSnapshot.data() as Map<String, dynamic>?;

                          final int freshPoints =
                              ((freshData?['points'] ?? 0) as num).toInt();

                          // Compute usage
                          final int pointsToUse =
                              (int.tryParse(pointsToUseController.text) ?? 0)
                                  .clamp(0, freshPoints);
                          // enforce eligibility rule: points usable only if freshPoints > 100
                          if (pointsToUse > 0 && freshPoints <= 100) {
                            // Block usage if not eligible
                            Get.snackbar(
                              "Points not usable",
                              "Customer must have more than 100 points to use points as discount.",
                              backgroundColor: Colors.orange.shade300,
                              colorText: Colors.white,
                            );
                            isLoading.value = false;
                            return;
                          }

                          final double manualDiscount =
                              double.tryParse(discountController.text) ?? 0.0;
                          final double totalDiscount = (manualDiscount +
                                  pointsToUse)
                              .clamp(0.0, originalTotal);
                          final double discountedTotal = (originalTotal -
                                  totalDiscount)
                              .clamp(0.0, double.infinity);

                          // Earn points rule: +1 if final total >= 200 (you can tweak as needed)
                          final int earnedPoints =
                              discountedTotal >= 200.0 ? 1 : 0;

                          final int newPoints =
                              freshPoints - pointsToUse + earnedPoints;

                          // Prepare pointsInfo to pass to PDF generator
                          final Map<String, dynamic> pointsInfo = {
                            'originalPoints': freshPoints,
                            'pointsUsed': pointsToUse,
                            'pointsEarned': earnedPoints,
                            'pointsRemaining': newPoints,
                          };

                          // Generate PDF (ensure your generateInvoicePDF signature accepts pointsInfo)
                          await printingController.generateInvoicePDF(
                            order,
                            discountedTotal,
                            totalDiscount,
                            {'name': name, 'mobile': mobile},
                            pointsInfo, // new param: points details for PDF
                          );

                          // Update customer points and name (if changed)
                          await custDocRef.update({
                            'points': newPoints,
                            'name': name,
                          });

                          // Update order document with final status + meta
                          await FirebaseFirestore.instance
                              .collection('orders')
                              .doc(docId)
                              .update({
                                'status': 'delivered',
                                'name': name,
                                'phone': mobile,
                                'manualDiscount': manualDiscount,
                                'previousPoint': freshPoints,
                                'pointsUsed': pointsToUse,
                                'pointsRemaining': newPoints,
                                'pointsEarned': earnedPoints,
                              });

                          Get.back();
                          
completer.complete(true); // close dialog
                          Get.snackbar(
                            "Invoice Generated",
                            "Customer: $name\nTotal: BDT ${discountedTotal.toStringAsFixed(2)}\nPoints used: $pointsToUse\nPoints remaining: $newPoints",
                            backgroundColor: Colors.green.shade400,
                            colorText: Colors.white,
                            duration: const Duration(seconds: 4),
                          );
                        } catch (e, st) {
                          debugPrint('Invoice generation failed: $e\n$st');
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
    return completer.future;
  }
}
