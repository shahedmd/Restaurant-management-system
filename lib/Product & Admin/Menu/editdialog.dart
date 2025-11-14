// ignore_for_file: use_build_context_synchronously

import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'controller.dart';

void showEditMenuDialog(BuildContext context, QueryDocumentSnapshot doc) {
  final MenuGetxCtrl controller = Get.find();
  final data = doc.data() as Map<String, dynamic>;

  final nameCtrl = TextEditingController(text: data["name"]);
  final priceCtrl = TextEditingController(text: data["price"].toString());
  RxString category = (data["category"] as String).obs;

  Uint8List? selectedImage;

  showDialog(
    context: context,
    builder: (context) {
      return Obx(
        () => AlertDialog(
          title: Text("Edit Menu", style: TextStyle(fontSize: 18.sp)),
          content: SizedBox(
            width: 350.w,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Category Dropdown
                DropdownButton<String>(
                  value: category.value,
                  items: const [
                    DropdownMenuItem(value: "Thai", child: Text("Thai")),
                    DropdownMenuItem(
                      value: "Fastfood",
                      child: Text("Fastfood"),
                    ),
                    DropdownMenuItem(value: "Chinese", child: Text("Chinese")),
                    DropdownMenuItem(value: "Indian", child: Text("Indian")),
                    DropdownMenuItem(value: "Drink", child: Text("Drink")),
                  ],
                  onChanged: (value) => category.value = value!,
                ),
                SizedBox(height: 10.h),

                // Name
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: "Food Name"),
                ),
                SizedBox(height: 10.h),

                // Price
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Price"),
                ),
                SizedBox(height: 15.h),

                // Pick Image
                ElevatedButton(
                  onPressed: () async {
                    final img = await controller.pickImageWeb();
                    if (img != null) selectedImage = img;
                    (context as Element).markNeedsBuild();
                  },
                  child: const Text("Change Image"),
                ),
                SizedBox(height: 10.h),

                // Show image
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.r),
                  child:
                      selectedImage == null
                          ? Image.network(data["imgUrl"], height: 120.h)
                          : Image.memory(selectedImage!, height: 120.h),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                String imgUrl = data["imgUrl"];
                if (selectedImage != null) {
                  imgUrl = await controller.uploadToImgbb(selectedImage!);
                }

                await controller.updateItem(
                  collection: "menu",
                  docId: doc.id, // <-- use snapshot id
                  name: nameCtrl.text.trim(),
                  price: int.tryParse(priceCtrl.text.trim()) ?? data["price"],
                  category: category.value,
                  imgUrl: imgUrl,
                );

                Navigator.pop(context);
              },
              child: const Text("Update"),
            ),
          ],
        ),
      );
    },
  );
}
