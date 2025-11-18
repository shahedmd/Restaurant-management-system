import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'controller.dart';

void addTransactionDialog(GBController controller, String id) {
  final amountC = TextEditingController();
  final noteC = TextEditingController();
  DateTime? selectedDate;

  Get.defaultDialog(
    title: "Add Transaction",
    content: Obx(
      () =>
          controller.gbIsloading.value
              ? Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  TextField(
                    controller: amountC,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "Amount",
                      prefixIcon: Center(
                        widthFactor: 1,
                        child: FaIcon(
                          FontAwesomeIcons.coins,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  TextField(
                    controller: noteC,
                    decoration: InputDecoration(
                      hintText: "Note",
                      prefixIcon: Center(
                        widthFactor: 1,
                        child: FaIcon(
                          FontAwesomeIcons.noteSticky,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed:
                            controller.gbIsloading.value
                                ? null
                                : () {
                                  controller.addTransaction(
                                    id,
                                    double.parse(amountC.text),
                                    noteC.text,
                                    "credit",
                                    selectedDate ?? DateTime.now(),
                                  );
                                  Get.back();
                                },
                        child: Text("Credit"),
                      ),
                      ElevatedButton(
                        onPressed:
                            controller.gbIsloading.value
                                ? null
                                : () {
                                  controller.addTransaction(
                                    id,
                                    double.parse(amountC.text),
                                    noteC.text,
                                    "debit",
                                    selectedDate ?? DateTime.now(),
                                  );
                                  Get.back();
                                },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                        ),
                        child: Text("Debit"),
                      ),
                    ],
                  ),
                ],
              ),
    ),
  );
}
