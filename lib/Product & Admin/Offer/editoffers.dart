import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../Menu/controller.dart';


void showEditOfferDialog(
    BuildContext context, QueryDocumentSnapshot doc, MenuGetxCtrl controller) {

  final data = doc.data() as Map<String, dynamic>;

  final nameCtrl = TextEditingController(text: data["name"]);
  final priceCtrl = TextEditingController(text: data["price"].toString());
  final validateCtrl = TextEditingController(
      text: data["validate"].toDate().toString().split(' ')[0]);

  Uint8List? newImage;
  DateTime selectedDate = data["validate"].toDate();

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: const Text("Edit Offer"),
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

                TextField(
                  controller: validateCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: "Valid Till"),
                  onTap: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );

                    if (picked != null) {
                      selectedDate = picked;
                      validateCtrl.text = picked.toString().split(" ")[0];
                    }
                  },
                ),

                const SizedBox(height: 10),

                ElevatedButton(
                  onPressed: () async {
                    Uint8List? img = await controller.pickImageWeb();
                    setState(() => newImage = img);
                                    },
                  child: const Text("Replace Image"),
                ),

                if (newImage != null)
                  const Text("New image selected ✔",
                      style: TextStyle(color: Colors.green)),
              ],
            ),
          ),

          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),

            ElevatedButton(
              onPressed: () async {
                String imageUrl = data["imgUrl"]; // keep old image by default

                if (newImage != null) {
                  imageUrl = await controller.uploadToImgbb(newImage!);
                }

                await controller.updateItem(
                  docId: doc.id,
                  name: nameCtrl.text,
                  price: int.parse(priceCtrl.text),
                  imgUrl: imageUrl,
                  validate: selectedDate,
                  collection: "offers",
                );

                Get.back();
              },
              child: const Text("Update"),
            ),
          ],
        );
      });
    },
  );
}
