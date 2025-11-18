// ignore_for_file: use_build_context_synchronously

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'controller.dart';

void showCreateMenuDialog(BuildContext context) {
  final MenuGetxCtrl controller = Get.find();

  final nameCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  RxString selectedCategory = (controller.categories.isNotEmpty ? controller.categories.first : "").obs;
  RxList<Map<String, dynamic>> variants = <Map<String, dynamic>>[].obs;
  Uint8List? selectedImage;

  showDialog(
    context: context,
    builder: (context) => Obx(
      () => AlertDialog(
        title: const Text("Create Menu Item"),
        content: SizedBox(
          width: 400.w,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ---------------- CATEGORY DROPDOWN ----------------
                DropdownButton<String>(
                  value: selectedCategory.value.isNotEmpty ? selectedCategory.value : null,
                  items: controller.categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) => selectedCategory.value = val ?? "",
                  hint: const Text("Select category"),
                ),
                SizedBox(height: 10.h),

                // ---------------- NAME ----------------
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: "Item Name"),
                ),
                SizedBox(height: 10.h),

                // ---------------- SINGLE PRICE ----------------
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Price (if no variants)"),
                ),
                SizedBox(height: 10.h),

                // ---------------- VARIANTS ----------------
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Variants"),
                    ElevatedButton(
                      onPressed: () {
                        variants.add({"size": "", "price": 0});
                      },
                      child: const Text("Add"),
                    ),
                  ],
                ),
                ...variants.asMap().entries.map((entry) {
                  final index = entry.key;
                  final v = entry.value;
                  final sizeCtrl = TextEditingController(text: v["size"]);
                  final priceCtrlVar = TextEditingController(text: v["price"].toString());

                  return Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: sizeCtrl,
                          decoration: const InputDecoration(labelText: "Size"),
                          onChanged: (val) => v["size"] = val,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: TextField(
                          controller: priceCtrlVar,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: "Price"),
                          onChanged: (val) => v["price"] = int.tryParse(val) ?? 0,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => variants.removeAt(index),
                      )
                    ],
                  );
                }),

                SizedBox(height: 10.h),

                // ---------------- IMAGE ----------------
                ElevatedButton(
                  onPressed: () async {
                    final img = await controller.pickImageWeb();
                    if (img != null) selectedImage = img;
                  },
                  child: const Text("Select Image"),
                ),
                SizedBox(height: 10.h),
                if (selectedImage != null) Image.memory(selectedImage!, height: 120.h),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty || (priceCtrl.text.isEmpty && variants.isEmpty) || selectedImage == null) {
                Get.snackbar("Error", "Please fill all required fields and select an image");
                return;
              }

              await controller.createItem(
                name: nameCtrl.text.trim(),
                price: variants.isEmpty ? int.tryParse(priceCtrl.text.trim()) : null,
                variants: variants.isNotEmpty ? variants.toList() : null,
                imageBytes: selectedImage!,
                category: selectedCategory.value,
                collection: "menu",
              );

              Navigator.pop(context);
            },
            child: const Text("Create"),
          ),
        ],
      ),
    ),
  );
}