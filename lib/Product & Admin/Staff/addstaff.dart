import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controller.dart';

void addStaffDialog(StaffController controller) {
  final nameC = TextEditingController();
  final phoneC = TextEditingController();
  DateTime? selectedDate;

  Get.defaultDialog(
    title: "Add Staff",
    content: Column(
      children: [
        TextField(controller: nameC, decoration: InputDecoration(hintText: "Name")),
        TextField(controller: phoneC, decoration: InputDecoration(hintText: "Phone")),
        SizedBox(height: 10),

        ElevatedButton(
          onPressed: () async {
            selectedDate = await showDatePicker(
              context: Get.context!,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
          },
          child: Text("Choose Joining Date"),
        ),
      ],
    ),
    textConfirm: "Save",
    onConfirm: () {
      if (selectedDate != null) {
        controller.addStaff(nameC.text, phoneC.text, selectedDate!);
        Get.back();
      }
    },
  );
}
