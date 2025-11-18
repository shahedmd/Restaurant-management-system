// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:restaurant_management/Product%20&%20Admin/Menu/controller.dart';

void showEditMenuDialog(BuildContext context, QueryDocumentSnapshot doc) {
  final MenuGetxCtrl controller = Get.find();
  final data = doc.data() as Map<String, dynamic>;

  final nameCtrl = TextEditingController(text: data["name"]);
  final priceCtrl = TextEditingController(
    text: data.containsKey("price") ? data["price"].toString() : "",
  );

  // Handle variants if any
  List<Map<String, dynamic>> variants = [];
  if (data.containsKey("variants") && data["variants"] is List) {
    variants = List<Map<String, dynamic>>.from(data["variants"]);
  }

  // RxString for selected category
  final categoryFromDb = data["category"] as String?;
  RxString selectedCategory = (categoryFromDb ?? "").obs;

  Uint8List? selectedImage;

  showDialog(
    context: context,
    builder: (context) {
      return Obx(() {
        return AlertDialog(
          title: Text("Edit Menu", style: TextStyle(fontSize: 18.sp)),
          content: SizedBox(
            width: 350.w,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Category dropdown
                  DropdownButton<String>(
                      value:
                          controller.categories.contains(selectedCategory.value)
                              ? selectedCategory.value
                              : null,
                      items:
                          controller.categories
                              .map(
                                (c) =>
                                    DropdownMenuItem(value: c, child: Text(c)),
                              )
                              .toList(),
                      onChanged: (val) {
                        if (val != null) selectedCategory.value = val;
                      },
                      hint: const Text("Select category"),
                      isExpanded: true,
                    ),
                  
                  SizedBox(height: 10.h),

                  // Name field
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: "Food Name"),
                  ),
                  SizedBox(height: 10.h),

                  // Price field (only for single-price items)
                  if (variants.isEmpty)
                    TextField(
                      controller: priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Price"),
                    ),

                  SizedBox(height: 10.h),

                  // Variants (if exists)
                  if (variants.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Variants",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        ...variants.asMap().entries.map((entry) {
                          int idx = entry.key;
                          Map<String, dynamic> v = entry.value;
                          final sizeCtrl = TextEditingController(
                            text: v["size"],
                          );
                          final priceVarCtrl = TextEditingController(
                            text: v["price"].toString(),
                          );
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 5.h),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: sizeCtrl,
                                    decoration: const InputDecoration(
                                      labelText: "Size",
                                    ),
                                    onChanged:
                                        (val) => variants[idx]["size"] = val,
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: TextField(
                                    controller: priceVarCtrl,
                                    decoration: const InputDecoration(
                                      labelText: "Price",
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged:
                                        (val) =>
                                            variants[idx]["price"] =
                                                int.tryParse(val) ?? 0,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),

                  SizedBox(height: 15.h),

                  // Change image button
                  ElevatedButton(
                    onPressed: () async {
                      final img = await controller.pickImageWeb();
                      if (img != null) selectedImage = img;
                      (context as Element).markNeedsBuild();
                    },
                    child: const Text("Change Image"),
                  ),
                  SizedBox(height: 10.h),

                  // Show image preview
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10.r),
                    child:
                        selectedImage != null
                            ? Image.memory(selectedImage!, height: 120.h)
                            : Image.network(data["imgUrl"], height: 120.h),
                  ),
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
                String imgUrl = data["imgUrl"];
                if (selectedImage != null) {
                  imgUrl = await controller.uploadToImgbb(selectedImage!);
                }

                // For single-price item
                int? price =
                    variants.isEmpty
                        ? int.tryParse(priceCtrl.text.trim())
                        : null;

                await controller.updateItem(
                  docId: doc.id,
                  name: nameCtrl.text.trim(),
                  price: price,
                  variants: variants.isNotEmpty ? variants : null,
                  imgUrl: imgUrl,
                  category: selectedCategory.value,
                  collection: "menu",
                );

                Navigator.pop(context);
              },
              child: const Text("Update"),
            ),
          ],
        );
      });
    },
  );
}
