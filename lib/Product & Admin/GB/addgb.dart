import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controller.dart';


void addGBDialog(GBController controller) {
  final nameC = TextEditingController();
  final phoneC = TextEditingController();

  Get.defaultDialog(
    title: "Add Governing Body",
    content: Column(
      children: [
        TextField(controller: nameC, decoration: InputDecoration(hintText: "Name")),
        TextField(controller: phoneC, decoration: InputDecoration(hintText: "Phone")),
      ],
    ),
    textConfirm: "Save",
    onConfirm: () {
      controller.addBody(nameC.text, phoneC.text);
      Get.back();
    },
  );
}
