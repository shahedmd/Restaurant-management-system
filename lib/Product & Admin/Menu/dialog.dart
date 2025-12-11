// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'controller.dart';

/// ------------------------------
/// CREATE MENU DIALOG
/// ------------------------------
void showCreateMenuDialog(BuildContext context) {
  final MenuGetxCtrl controller = Get.find();

  final nameCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final descriptionCtrl = TextEditingController(); // New description field

  RxString selectedCategory =
      (controller.categories.isNotEmpty ? controller.categories.first : "").obs;
  RxList<Map<String, dynamic>> variants = <Map<String, dynamic>>[].obs;
  Uint8List? selectedImage;

  showDialog(
    context: context,
    builder: (context) => Obx(
      () => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        backgroundColor: Colors.white,
        insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),

        titlePadding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 10.h),
        title: Row(
          children: [
            Icon(FontAwesomeIcons.plusCircle, color: Colors.blue.shade600, size: 20.sp),
            SizedBox(width: 10.w),
            Text(
              "Create Menu Item",
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: Colors.blue.shade700,
              ),
            ),
          ],
        ),

        content: SizedBox(
          width: 420.w,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // CATEGORY
                Text("Category",
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp,
                        color: Colors.blue.shade600)),
                SizedBox(height: 6.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.r),
                    color: const Color(0xFFEAF3FF),
                  ),
                  child: DropdownButton<String>(
                    isExpanded: true,
                    underline: const SizedBox(),
                    value: selectedCategory.value.isNotEmpty ? selectedCategory.value : null,
                    icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.blue.shade600),
                    items: controller.categories
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c, style: TextStyle(fontSize: 14.sp)),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) selectedCategory.value = val;
                    },
                  ),
                ),
                SizedBox(height: 20.h),

                // NAME
                _inputBox(
                  controller: nameCtrl,
                  label: "Item Name",
                  icon: FontAwesomeIcons.bowlFood,
                ),
                SizedBox(height: 20.h),

                // DESCRIPTION
                Text("Description",
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp,
                        color: Colors.blue.shade600)),
                SizedBox(height: 6.h),
                _expandableDescriptionBox(descriptionCtrl),
                SizedBox(height: 20.h),

                // PRICE
                _inputBox(
                  controller: priceCtrl,
                  label: "Price (if no variants)",
                  icon: FontAwesomeIcons.tag,
                  keyboardNumber: true,
                ),
                SizedBox(height: 20.h),

                // VARIANTS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Variants",
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15.sp,
                            color: Colors.blue.shade700)),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade50,
                        foregroundColor: Colors.blue.shade700,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r)),
                      ),
                      onPressed: () {
                        variants.add({"size": "", "price": 0});
                      },
                      icon: Icon(FontAwesomeIcons.plus, size: 14.sp),
                      label: Text("Add Variant", style: TextStyle(fontSize: 13.sp)),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),

                ...variants.asMap().entries.map((entry) {
                  final index = entry.key;
                  final v = entry.value;
                  final sizeCtrl = TextEditingController(text: v["size"]);
                  final priceCtrlVar = TextEditingController(text: v["price"].toString());

                  return Container(
                    padding: EdgeInsets.all(12.w),
                    margin: EdgeInsets.only(bottom: 12.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF3FF),
                      borderRadius: BorderRadius.circular(18.r),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _inputBox(
                            controller: sizeCtrl,
                            label: "Size",
                            icon: FontAwesomeIcons.ruler,
                            onChanged: (val) => v["size"] = val,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: _inputBox(
                            controller: priceCtrlVar,
                            label: "Price",
                            icon: FontAwesomeIcons.tag,
                            keyboardNumber: true,
                            onChanged: (val) => v["price"] = int.tryParse(val) ?? 0,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        GestureDetector(
                          onTap: () => variants.removeAt(index),
                          child: Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(FontAwesomeIcons.xmark, size: 14.sp, color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                SizedBox(height: 20.h),

                // IMAGE PICKER
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 20.w),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                  ),
                  onPressed: () async {
                    final img = await controller.pickImageWeb();
                    if (img != null) selectedImage = img;
                    (context as Element).markNeedsBuild();
                  },
                  icon: const Icon(FontAwesomeIcons.image, color: Colors.white),
                  label: Text("Select Image", style: TextStyle(color: Colors.white)),
                ),

                SizedBox(height: 12.h),
                if (selectedImage != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16.r),
                    child: Image.memory(selectedImage!, height: 160.h, fit: BoxFit.cover),
                  ),
              ],
            ),
          ),
        ),

        actionsPadding: EdgeInsets.only(right: 20.w, bottom: 12.h),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: Colors.red, fontSize: 14.sp)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 12.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
            ),
            onPressed: () async {
              if (nameCtrl.text.isEmpty ||
                  (priceCtrl.text.isEmpty && variants.isEmpty) ||
                  selectedImage == null) {
                Get.snackbar("Error", "Please fill all required fields and select an image");
                return;
              }

              await controller.createItem(
                name: nameCtrl.text.trim(),
                description: descriptionCtrl.text.trim(),
                price: variants.isEmpty ? int.tryParse(priceCtrl.text.trim()) : null,
                variants: variants.isNotEmpty ? variants.toList() : null,
                imageBytes: selectedImage!,
                category: selectedCategory.value,
                collection: "menu",
              );

              Navigator.pop(context);
            },
            child: Text("Create", style: TextStyle(fontSize: 14.sp, color: Colors.white)),
          ),
        ],
      ),
    ),
  );
}

/// COMPONENT: BEAUTIFUL INPUT BOX
Widget _inputBox({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  bool keyboardNumber = false,
  Function(String)? onChanged,
}) {
  return TextField(
    controller: controller,
    keyboardType: keyboardNumber ? TextInputType.number : TextInputType.text,
    onChanged: onChanged,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 16.sp, color: Colors.blue.shade600),
      filled: true,
      fillColor: const Color(0xFFEAF3FF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: BorderSide(color: Colors.blue.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: BorderSide(color: Colors.blue.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: BorderSide(color: Colors.blue.shade700, width: 1.5),
      ),
    ),
  );
}

Widget _expandableDescriptionBox(TextEditingController controller) {
  return ConstrainedBox(
    constraints: BoxConstraints(minHeight: 80.h, maxHeight: 180.h),
    child: TextField(
      controller: controller,
      maxLines: null,
      expands: false,
      textAlignVertical: TextAlignVertical.center,
      decoration: InputDecoration(
        labelText: "Write description...",
        alignLabelWithHint: true,
        filled: true,
        fillColor: const Color(0xFFEAF3FF),
        prefixIcon: Icon(FontAwesomeIcons.alignLeft, color: Colors.blue.shade600, size: 14.sp),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: Colors.blue.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: Colors.blue.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: Colors.blue.shade700, width: 1.5),
        ),
      ),
    ),
  );
}