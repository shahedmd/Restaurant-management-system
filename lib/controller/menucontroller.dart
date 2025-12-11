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
    final TextEditingController transactionController = TextEditingController(
      text: order['transactionId'] ?? '',
    );

    final RxString customerName = ''.obs;
    final RxInt customerPoints = 0.obs;
    final RxBool pointsAllowed = false.obs;
    final RxDouble computedTotal = RxDouble((order['total'] ?? 0));
    final double originalTotal = ((order['total'] ?? 0) as num).toDouble();
    final RxBool isLoading = false.obs;
    final Completer<bool> completer = Completer<bool>();

    Timer? debounce;

    // Determine if this is Inhouse order
    final bool isInhouse = order['orderType'] == 'Inhouse';

    // Available payment methods for Inhouse orders
    final List<String> paymentMethods = ['Cash', 'Bkash', 'Nagad', 'Bank'];
    final RxString selectedPaymentMethod = RxString(
      isInhouse
          ? (order['paymentMethod'] != null && order['paymentMethod'] != '')
              ? order['paymentMethod']
              : 'Cash'
          : (order['paymentMethod'] ?? 'Cash'),
    );

    // Fetch customer by mobile
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
          if (customerName.value.isNotEmpty) {
            nameController.text = customerName.value;
          }
        } else {
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

    // Initialize on open
    final initialMobile = mobileController.text.trim();
    if (initialMobile.isNotEmpty) fetchCustomerByMobile(initialMobile);

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
                        // Mobile input
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
                              onPressed:
                                  () => fetchCustomerByMobile(
                                    mobileController.text.trim(),
                                  ),
                            ),
                          ),
                          onChanged: (val) {
                            debounce?.cancel();
                            debounce = Timer(
                              const Duration(milliseconds: 500),
                              () => fetchCustomerByMobile(val.trim()),
                            );
                          },
                        ),
                        SizedBox(height: 10.h),
                        // Name input
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
                        // Points info (read-only)
                        Obx(
                          () => TextField(
                            controller: TextEditingController(
                              text: customerPoints.value.toString(),
                            ),
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: "Customer Points (available)",
                              border: const OutlineInputBorder(),
                              helperText:
                                  pointsAllowed.value
                                      ? 'Points can be used (>100)'
                                      : 'Customer needs >100 points',
                            ),
                          ),
                        ),
                        SizedBox(height: 10.h),
                        // Points to use input
                        Obx(
                          () => TextField(
                            controller: pointsToUseController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: "Points to Use (BDT)",
                              border: const OutlineInputBorder(),
                              helperText:
                                  pointsAllowed.value
                                      ? 'Max ${customerPoints.value}'
                                      : 'Not eligible',
                            ),
                            enabled: pointsAllowed.value,
                            onChanged: (val) {
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
                        ),
                        SizedBox(height: 10.h),
                        // Manual discount
                        TextField(
                          controller: discountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: "Manual Discount (BDT)",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 10.h),
                        // Payment Method (only editable for Inhouse)
                        DropdownButtonFormField<String>(
                          value: selectedPaymentMethod.value,
                          items:
                              paymentMethods
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              isInhouse
                                  ? (val) {
                                    if (val != null) {
                                      selectedPaymentMethod.value = val;
                                    }
                                  }
                                  : null,
                          decoration: const InputDecoration(
                            labelText: "Payment Method",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 10.h),
                        // Transaction ID (only required for Inhouse non-Cash)
                        if (isInhouse && selectedPaymentMethod.value != 'Cash')
                          TextField(
                            controller: transactionController,
                            decoration: const InputDecoration(
                              labelText: "Transaction ID",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        SizedBox(height: 12.h),
                        // Calculation summary
                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: discountController,
                          builder: (context, discountValue, _) {
                            final manualDiscount =
                                double.tryParse(discountValue.text) ?? 0.0;
                            final pointsUsed =
                                int.tryParse(pointsToUseController.text) ?? 0;
                            final totalDiscount = (manualDiscount + pointsUsed)
                                .clamp(0.0, originalTotal);
                            final finalTotal = (originalTotal - totalDiscount)
                                .clamp(0.0, double.infinity);

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
                                    "Points Used: BDT $pointsUsed",
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

                        if (isInhouse &&
                            selectedPaymentMethod.value != 'Cash' &&
                            transactionController.text.trim().isEmpty) {
                          Get.snackbar(
                            "Error",
                            "Transaction ID required for ${selectedPaymentMethod.value}",
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

                          DocumentReference custDocRef;
                          int freshPoints = 0;

                          if (query.docs.isNotEmpty) {
                            custDocRef = query.docs.first.reference;
                            final data = query.docs.first.data();
                            freshPoints =
                                ((data['points'] ?? 0) as num).toInt();
                          } else {
                            custDocRef = await customerRef.add({
                              'mobile': mobile,
                              'name': name,
                              'points': 0,
                            });
                          }

                          final int pointsToUse =
                              (int.tryParse(pointsToUseController.text) ?? 0)
                                  .clamp(0, freshPoints);
                          if (pointsToUse > 0 && freshPoints <= 100) {
                            Get.snackbar(
                              "Points not usable",
                              "Customer must have more than 100 points",
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

                          final int earnedPoints = (discountedTotal ~/ 100) * 2;
                          final int newPoints =
                              freshPoints - pointsToUse + earnedPoints;

                          // Batch update
                          final batch = FirebaseFirestore.instance.batch();
                          batch.update(custDocRef, {
                            'points': newPoints,
                            'name': name,
                          });

                          final orderUpdate = {
                            'status': 'delivered',
                            'name': name,
                            'phone': mobile,
                            'manualDiscount': manualDiscount,
                            'previousPoint': freshPoints,
                            'pointsUsed': pointsToUse,
                            'pointsRemaining': newPoints,
                            'pointsEarned': earnedPoints,
                          };

                          if (isInhouse) {
                            orderUpdate['paymentMethod'] =
                                selectedPaymentMethod.value;
                            orderUpdate['transactionId'] =
                                selectedPaymentMethod.value == 'Cash'
                                    ? ''
                                    : transactionController.text.trim();
                          }

                          batch.update(
                            FirebaseFirestore.instance
                                .collection('orders')
                                .doc(docId),
                            orderUpdate,
                          );

                          Future.microtask(
                            () => printingController
                                .generateInvoicePDF(
                                  order,
                                  discountedTotal,
                                  totalDiscount,
                                  {'name': name, 'mobile': mobile},
                                  {
                                    'originalPoints': freshPoints,
                                    'pointsUsed': pointsToUse,
                                    'pointsEarned': earnedPoints,
                                    'pointsRemaining': newPoints,
                                  },
                                  paymentMethodOverride:
                                      selectedPaymentMethod.value,
                                  transactionIdOverride:
                                      selectedPaymentMethod.value == 'Cash'
                                          ? ''
                                          : transactionController.text.trim(),
                                ),
                          );

                          await batch.commit();
                          Get.back();
                          completer.complete(true);

                          Get.snackbar(
                            "Invoice Generated",
                            "Customer: $name\nTotal: BDT ${discountedTotal.toStringAsFixed(2)}\nPoints remaining: $newPoints",
                            backgroundColor: Colors.green.shade400,
                            colorText: Colors.white,
                            duration: const Duration(days: 1),
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
