import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controller.dart';
void addSalaryDialog(StaffController controller, String staffId) {
  final amountC = TextEditingController();
  final noteC = TextEditingController();
  final monthC = TextEditingController();

  Get.defaultDialog(
    title: "Add Salary",
    content: Column(
      children: [
        TextField(
          controller: amountC,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: "Amount"),
        ),
        TextField(
          controller: monthC,
          decoration: InputDecoration(hintText: "Month (e.g. January)"),
        ),
        TextField(
          controller: noteC,
          decoration: InputDecoration(hintText: "Note"),
        ),
      ],
    ),
    textConfirm: "Save",
    onConfirm: () {
      controller.addSalary(
        staffId,
        double.parse(amountC.text),
        noteC.text,
        monthC.text,
      );
      Get.back();
    },
  );
}
