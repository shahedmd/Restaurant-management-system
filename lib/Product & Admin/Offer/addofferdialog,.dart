// ignore_for_file: file_names, use_build_context_synchronously, deprecated_member_use
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../Menu/controller.dart';

void showAddOfferDialog(BuildContext context, MenuGetxCtrl controller) {
  final nameCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final validateCtrl = TextEditingController();
  Uint8List? pickedImage;
  DateTime? selectedDate;
  RxList<Map<String, dynamic>> variants = <Map<String, dynamic>>[].obs;

  RxBool isLoading = false.obs;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(builder: (context, setState) {
        return Obx(
          () => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
            title: Row(
              children: [
                Icon(FontAwesomeIcons.plus, color: Colors.blue, size: 20.sp),
                SizedBox(width: 10.w),
                Text("Add Offer", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600)),
              ],
            ),
            content: SizedBox(
              width: 400.w,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // NAME
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: "Offer Name",
                        prefixIcon: Icon(FontAwesomeIcons.tag, color: Colors.blue, size: 16.sp),
                        filled: true,
                        fillColor: Colors.blue.withOpacity(0.06),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: Colors.blue.shade200),
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),

                    // PRICE IF NO VARIANTS
                    if (variants.isEmpty)
                      TextField(
                        controller: priceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "Price (if no variants)",
                          prefixIcon: Icon(FontAwesomeIcons.moneyBill1Wave, color: Colors.blue, size: 16.sp),
                          filled: true,
                          fillColor: Colors.blue.withOpacity(0.06),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(color: Colors.blue.shade200),
                          ),
                        ),
                      ),
                    SizedBox(height: 12.h),

                    // VALID DATE
                    TextField(
                      controller: validateCtrl,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: "Valid Till Date",
                        prefixIcon: Icon(FontAwesomeIcons.calendar, color: Colors.blue, size: 16.sp),
                        filled: true,
                        fillColor: Colors.blue.withOpacity(0.06),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: Colors.blue.shade200),
                        ),
                      ),
                      onTap: () async {
                        DateTime? date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          selectedDate = date;
                          validateCtrl.text = DateFormat('dd MMM yyyy').format(date);
                        }
                      },
                    ),
                    SizedBox(height: 12.h),

                    // VARIANTS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Variants", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                          ),
                          icon: Icon(FontAwesomeIcons.plus, size: 14.sp, color: Colors.white),
                          label: const Text("Add", style: TextStyle(color: Colors.white)),
                          onPressed: () => variants.add({"size": "", "price": 0}),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),

                    ...variants.asMap().entries.map((entry) {
                      final index = entry.key;
                      final v = entry.value;
                      final sizeCtrl = TextEditingController(text: v["size"]);
                      final priceCtrlVar = TextEditingController(text: v["price"].toString());

                      return Container(
                        margin: EdgeInsets.only(bottom: 10.h),
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
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
                              icon: Icon(FontAwesomeIcons.trash, color: Colors.red, size: 16.sp),
                              onPressed: () => variants.removeAt(index),
                            ),
                          ],
                        ),
                      );
                    }),

                    SizedBox(height: 10.h),

                    // IMAGE PICK
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 18.w),
                      ),
                      icon: Icon(FontAwesomeIcons.image, size: 16.sp, color: Colors.white),
                      label: const Text("Pick Image", style: TextStyle(color: Colors.white)),
                      onPressed: () async {
                        Uint8List? img = await controller.pickImageWeb();
                        if (img != null) setState(() => pickedImage = img);
                      },
                    ),
                    SizedBox(height: 10.h),
                    if (pickedImage != null)
                      Container(
                        height: 120.h,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Image.memory(pickedImage!, fit: BoxFit.cover),
                      ),

                    if (isLoading.value) const Padding(
                      padding: EdgeInsets.only(top: 15.0),
                      child: CircularProgressIndicator(),
                    ),
                  ],
                ),
              ),
            ),

            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: Text("Cancel", style: TextStyle(color: Colors.red.shade700)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                onPressed: isLoading.value
                    ? null
                    : () async {
                        if (nameCtrl.text.isEmpty ||
                            (priceCtrl.text.isEmpty && variants.isEmpty) ||
                            pickedImage == null ||
                            selectedDate == null) {
                          Get.snackbar("Error", "Please fill all required fields");
                          return;
                        }
                        isLoading.value = true;
                        await controller.createItem(
                          name: nameCtrl.text.trim(),
                          price: variants.isEmpty ? int.parse(priceCtrl.text.trim()) : null,
                          variants: variants.isNotEmpty ? variants.toList() : null,
                          imageBytes: pickedImage!,
                          validate: selectedDate,
                          collection: "offers",
                        );
                        isLoading.value = false;
                        Get.back();
                      },
                child: Text("Add", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      });
    },
  );
}
