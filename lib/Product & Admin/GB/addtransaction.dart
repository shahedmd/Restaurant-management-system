import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controller.dart';


void addTransactionDialog(GBController controller, String id) {
  final amountC = TextEditingController();
  final noteC = TextEditingController();

  Get.defaultDialog(
    title: "Add Transaction",
    content: Column(
      children: [
        TextField(
          controller: amountC,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: "Amount"),
        ),
        TextField(
          controller: noteC,
          decoration: InputDecoration(hintText: "Note"),
        ),
        SizedBox(height: 10),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () {
                controller.addTransaction(
                    id, double.parse(amountC.text), noteC.text, "credit");
                Get.back();
              },
              child: Text("Credit"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                controller.addTransaction(
                    id, double.parse(amountC.text), noteC.text, "debit");
                Get.back();
              },
              child: Text("Debit"),
            ),
          ],
        )
      ],
    ),
  );
}
