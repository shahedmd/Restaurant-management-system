// ignore_for_file: file_names

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../Menu/controller.dart';

void showAddOfferDialog(BuildContext context, MenuGetxCtrl controller) {
  final nameCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final validateCtrl = TextEditingController();

  Uint8List? pickedImage;
  DateTime? selectedDate;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: const Text("Add Offer"),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: "Offer Name"),
                ),
                TextField(
                  controller: priceCtrl,
                  decoration: const InputDecoration(labelText: "Price"),
                  keyboardType: TextInputType.number,
                ),

                // VALIDATE DATE PICKER
                TextField(
                  controller: validateCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: "Valid Till Date"),
                  onTap: () async {
                    DateTime? date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      selectedDate = date;
                      validateCtrl.text = date.toString().split(" ")[0];
                    }
                  },
                ),

                const SizedBox(height: 10),

                // IMAGE PICK
                ElevatedButton(
                  onPressed: () async {
                    Uint8List? img = await controller.pickImageWeb();
                    if (img != null) {
                      setState(() => pickedImage = img);
                    }
                  },
                  child: const Text("Pick Image"),
                ),

                if (pickedImage != null)
                  const Text("Image selected ✔", style: TextStyle(color: Colors.green)),
              ],
            ),
          ),

          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),

            ElevatedButton(
              onPressed: () async {
                if (pickedImage == null) {
                  Get.snackbar("Error", "Please select an image");
                  return;
                }

                if (selectedDate == null) {
                  Get.snackbar("Error", "Select a validity date");
                  return;
                }

                await controller.createItem(
                  name: nameCtrl.text,
                  price: int.parse(priceCtrl.text),
                  imageBytes: pickedImage!,
                  validate: selectedDate,
                  collection: "offers",
                );

                Get.back();
              },
              child: const Text("Add"),
            ),
          ],
        );
      });
    },
  );
}
