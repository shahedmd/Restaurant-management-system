// ignore_for_file: use_build_context_synchronously

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'controller.dart';

void showCreateMenuDialog(BuildContext context) {
  final MenuGetxCtrl menuController = Get.put(MenuGetxCtrl());

  final nameCtrl = TextEditingController();
  final priceCtrl = TextEditingController();

  // Reactive variables
  RxString selectedCategory = "Thai".obs;
  Rx<Uint8List?> selectedImage = Rx<Uint8List?>(null);

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text("Create Menu", style: TextStyle(fontSize: 18.sp)),
        content: SizedBox(
          width: 350.w,
          child: Obx(() {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // CATEGORY DROPDOWN
                DropdownButton<String>(
                  value: selectedCategory.value,
                  items: const [
                    DropdownMenuItem(value: "Thai", child: Text("Thai")),
                    DropdownMenuItem(value: "Fastfood", child: Text("Fastfood")),
                    DropdownMenuItem(value: "Chinese", child: Text("Chinese")),
                    DropdownMenuItem(value: "Indian", child: Text("Indian")),
                                        DropdownMenuItem(value: "Drink", child: Text("Drink")),

                  ],
                  onChanged: (value) {
                    selectedCategory.value = value!;
                  },
                ),

                SizedBox(height: 10.h),

                // NAME
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: "Food Name"),
                ),

                SizedBox(height: 10.h),

                // PRICE
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Price"),
                ),

                SizedBox(height: 15.h),

                // PICK IMAGE
                ElevatedButton(
                  onPressed: () async {
                    final img = await menuController.pickImageWeb();
                    if (img != null) {
                      selectedImage.value = img;
                    }
                  },
                  child: const Text("Pick Image"),
                ),

                SizedBox(height: 10.h),

                // IMAGE PREVIEW
                if (selectedImage.value != null)
                  Image.memory(selectedImage.value!, height: 120.h),
              ],
            );
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),

          ElevatedButton(
            onPressed: () async {
              if (selectedImage.value == null) return;

              await menuController.createItem(
                collection: "menu",
                category: selectedCategory.value,
                name: nameCtrl.text.trim(),
                price: int.parse(priceCtrl.text.trim()),
                imageBytes: selectedImage.value!,
              );

              Navigator.pop(context);
            },
            child: const Text("Create"),
          ),
        ],
      );
    },
  );
}
