// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:restaurant_management/Product & Admin/Menu/controller.dart';

void showEditMenuDialog(BuildContext context, QueryDocumentSnapshot doc) {
  final MenuGetxCtrl controller = Get.find();
  final data = doc.data() as Map<String, dynamic>;

  final nameCtrl = TextEditingController(text: data["name"]);
  final descriptionCtrl = TextEditingController(
    text: data.containsKey("description") ? data["description"] : "",
  );

  final priceCtrl = TextEditingController(
    text: data.containsKey("price") ? data["price"].toString() : "",
  );

  List<Map<String, dynamic>> variants = [];
  if (data.containsKey("variants") && data["variants"] is List) {
    variants = List<Map<String, dynamic>>.from(data["variants"]);
  }

  final categoryFromDb = data["category"] as String?;
  final RxString selectedCategory = (categoryFromDb ?? "").obs;

  Uint8List? selectedImage;

  showDialog(
    context: context,
    builder: (context) {
      return Obx(
        () => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          backgroundColor: Colors.white,
          insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),

          titlePadding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 10.h),
          title: Row(
            children: [
              Icon(
                FontAwesomeIcons.utensils,
                color: Colors.blue.shade600,
                size: 20.sp,
              ),
              SizedBox(width: 10.w),
              Text(
                "Edit Menu",
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
                  Text(
                    "Category",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                      color: Colors.blue.shade600,
                    ),
                  ),
                  SizedBox(height: 6.h),

                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16.r),
                      color: const Color(0xFFEAF3FF),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 6,
                          offset: Offset(0, 2),
                          color: Colors.black.withOpacity(0.08),
                        ),
                      ],
                    ),
                    child: DropdownButton<String>(
                      isExpanded: true,
                      underline: SizedBox(),
                      value:
                          controller.categories.contains(selectedCategory.value)
                              ? selectedCategory.value
                              : null,
                      icon: Icon(Icons.keyboard_arrow_down_rounded,
                          color: Colors.blue.shade600),
                      items: controller.categories
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(c, style: TextStyle(fontSize: 14.sp)),
                            ),
                          )
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
                    label: "Food Name",
                    icon: FontAwesomeIcons.bowlFood,
                  ),

                  SizedBox(height: 20.h),

                  Text(
                    "Description",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                      color: Colors.blue.shade600,
                    ),
                  ),
                  SizedBox(height: 6.h),

                  ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: 50.h,
                      maxHeight: 200.h, // expands but limited
                    ),
                    child: TextField(
                      controller: descriptionCtrl,
                      maxLines: null, // 🔥 Auto expandable
                      keyboardType: TextInputType.multiline,
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        alignLabelWithHint: true,
                        hintText: "Short item description...",
                        hintStyle: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey,
                        ),
                        prefixIcon: Icon(
                          FontAwesomeIcons.penToSquare,
                          size: 16.sp,
                          color: Colors.blue.shade600,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFEAF3FF),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 14.h,
                          horizontal: 12.w,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.r),
                          borderSide:
                              BorderSide(color: Colors.blue.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.r),
                          borderSide:
                              BorderSide(color: Colors.blue.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.r),
                          borderSide: BorderSide(
                            color: Colors.blue.shade700,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // PRICE INPUT (NO VARIANTS)
                  if (variants.isEmpty)
                    _inputBox(
                      controller: priceCtrl,
                      label: "Price",
                      icon: FontAwesomeIcons.tag,
                      keyboardNumber: true,
                    ),

                  // VARIANT SECTION (UNCHANGED)
                  if (variants.isNotEmpty) ...[
                    SizedBox(height: 16.h),
                    Text(
                      "Variants",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15.sp,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    SizedBox(height: 10.h),

                    ...variants.asMap().entries.map((entry) {
                      int idx = entry.key;
                      Map<String, dynamic> v = entry.value;

                      final sizeCtrl = TextEditingController(text: v["size"]);
                      final priceVarCtrl = TextEditingController(
                        text: v["price"].toString(),
                      );

                      return Container(
                        padding: EdgeInsets.all(12.w),
                        margin: EdgeInsets.only(bottom: 12.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF3FF),
                          borderRadius: BorderRadius.circular(18.r),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 8,
                              offset: Offset(0, 3),
                              color: Colors.black.withOpacity(0.08),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _inputBox(
                                controller: sizeCtrl,
                                label: "Size",
                                icon: FontAwesomeIcons.ruler,
                                onChanged: (val) => variants[idx]["size"] = val,
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: _inputBox(
                                controller: priceVarCtrl,
                                label: "Price",
                                icon: FontAwesomeIcons.tag,
                                keyboardNumber: true,
                                onChanged: (val) => variants[idx]["price"] =
                                    int.tryParse(val) ?? 0,
                              ),
                            ),
                            SizedBox(width: 6.w),

                            GestureDetector(
                              onTap: () {
                                variants.removeAt(idx);
                                (context as Element).markNeedsBuild();
                              },
                              child: Container(
                                padding: EdgeInsets.all(8.w),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  FontAwesomeIcons.xmark,
                                  size: 14.sp,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],

                  SizedBox(height: 10.h),

                  // ADD VARIANT BUTTON
                  Center(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade50,
                        foregroundColor: Colors.blue.shade700,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(
                          horizontal: 18.w,
                          vertical: 10.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                      ),
                      onPressed: () {
                        variants.add({"size": "", "price": 0});
                        (context as Element).markNeedsBuild();
                      },
                      icon: Icon(FontAwesomeIcons.plus, size: 14.sp),
                      label: Text("Add Variant", style: TextStyle(fontSize: 13.sp)),
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // IMAGE PICKER
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      padding: EdgeInsets.symmetric(
                        vertical: 12.h,
                        horizontal: 20.w,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    onPressed: () async {
                      final img = await controller.pickImageWeb();
                      if (img != null) selectedImage = img;
                      (context as Element).markNeedsBuild();
                    },
                    icon: Icon(FontAwesomeIcons.image, color: Colors.white),
                    label: Text("Change Image",
                        style: TextStyle(color: Colors.white)),
                  ),

                  SizedBox(height: 12.h),

                  // IMAGE PREVIEW
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16.r),
                    child: selectedImage != null
                        ? Image.memory(selectedImage!,
                            height: 160.h, fit: BoxFit.cover)
                        : CachedNetworkImage(
                            imageUrl: data["imgUrl"],
                            height: 180.h,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              height: 160.h,
                              color: Colors.blue.shade50,
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              height: 160.h,
                              color: Colors.grey.shade200,
                              child: Icon(Icons.broken_image, size: 40),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),

          actionsPadding: EdgeInsets.only(right: 20.w, bottom: 12.h),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel",
                  style: TextStyle(color: Colors.red, fontSize: 14.sp)),
            ),

            // UPDATE BUTTON
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              onPressed: () async {
                String imgUrl = data["imgUrl"];

                if (selectedImage != null) {
                  imgUrl = await controller.uploadToImgbb(selectedImage!);
                }

                int? price =
                    variants.isEmpty ? int.tryParse(priceCtrl.text.trim()) : null;

                await controller.updateItem(
                  docId: doc.id,
                  name: nameCtrl.text.trim(),
                  price: price,
                  variants: variants.isNotEmpty ? variants : null,
                  imgUrl: imgUrl,
                  category: selectedCategory.value,
                  collection: "menu",
                  description: descriptionCtrl.text.trim(),
                );

                Navigator.pop(context);
              },
              child:
                  Text("Update", style: TextStyle(color: Colors.white, fontSize: 14.sp)),
            ),
          ],
        ),
      );
    },
  );
}

// REUSABLE INPUT BOX
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
