import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controller.dart';

void addGBDialog(GBController controller) {
  final nameC = TextEditingController();
  final desC = TextEditingController();
  final nidC = TextEditingController();
  final phoneC = TextEditingController();

  Get.defaultDialog(
    title: "Add Governing Body Member",
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(controller: nameC, decoration: InputDecoration(hintText: "Name")),
        SizedBox(height: 8),
        TextField(controller: desC, decoration: InputDecoration(hintText: "Designation")),
        SizedBox(height: 8),
        TextField(controller: nidC, decoration: InputDecoration(hintText: "NID")),
        SizedBox(height: 8),
        TextField(controller: phoneC, decoration: InputDecoration(hintText: "Phone")),
      ],
    ),
    textConfirm: "Save",
    onConfirm: () {
      if (nameC.text.isNotEmpty &&
          desC.text.isNotEmpty &&
          nidC.text.isNotEmpty &&
          phoneC.text.isNotEmpty) {
        controller.addBody(
          name: nameC.text,
          des: desC.text,
          nid: nidC.text,
          phone: phoneC.text,
        );
        Get.back();
      } else {
        Get.snackbar("Error", "Please fill all fields",
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    },
  );
}
