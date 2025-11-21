// ignore_for_file: use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'Menu/controller.dart';

class CategoryPage extends StatefulWidget {
  final MenuGetxCtrl controller;
  const CategoryPage(this.controller, {super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final TextEditingController newCategoryCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(FontAwesomeIcons.tags, color: Colors.white, size: 20.sp),
            SizedBox(width: 10.w),
            const Text("Manage Categories"),
          ],
        ),
        backgroundColor: const Color.fromARGB(255, 2, 41, 87),
      ),
      body: Obx(
        () => Padding(
          padding: EdgeInsets.all(16.0.r),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Existing categories
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.controller.categories.length,
                  itemBuilder: (context, index) {
                    final category = widget.controller.categories[index];
                    final editCtrl = TextEditingController(text: category);

                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.h),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: editCtrl,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.blue.withOpacity(0.06),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                  borderSide: BorderSide(
                                    color: Colors.blue.shade200,
                                  ),
                                ),
                              ),
                              onSubmitted: (val) async {
                                if (val.trim().isEmpty) {
                                  Get.snackbar(
                                    "Error",
                                    "Category cannot be empty",
                                  );
                                  return;
                                }
                                widget.controller.categories[index] =
                                    val.trim();
                                await db
                                    .collection("category")
                                    .doc("VPSKqsQRbOLyz1aOloSG")
                                    .update({
                                      "categorylist":
                                          widget.controller.categories,
                                    });
                                Get.snackbar("Success", "Category updated");
                              },
                            ),
                          ),
                          SizedBox(width: 6.w),
                          InkWell(
                            onTap: () async {
                              widget.controller.categories.removeAt(index);
                              await db
                                  .collection("category")
                                  .doc("VPSKqsQRbOLyz1aOloSG")
                                  .update({
                                    "categorylist":
                                        widget.controller.categories,
                                  });
                              Get.snackbar("Success", "Category deleted");
                            },
                            child: Container(
                              padding: EdgeInsets.all(6.w),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Icon(
                                FontAwesomeIcons.trash,
                                color: Colors.red.shade700,
                                size: 16.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                SizedBox(height: 15.h),

                // Add new category
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: newCategoryCtrl,
                        decoration: InputDecoration(
                          hintText: "New Category",
                          filled: true,
                          fillColor: Colors.blue.withOpacity(0.06),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(color: Colors.blue.shade200),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: 12.h,
                          horizontal: 12.w,
                        ),
                      ),
                      icon: Icon(
                        FontAwesomeIcons.plus,
                        size: 14.sp,
                        color: Colors.white,
                      ),
                      label: const Text(
                        "Add",
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () async {
                        final val = newCategoryCtrl.text.trim();
                        if (val.isEmpty) {
                          Get.snackbar("Error", "Enter category name");
                          return;
                        }
                        widget.controller.categories.add(val);
                        await db
                            .collection("category")
                            .doc("VPSKqsQRbOLyz1aOloSG")
                            .update({
                              "categorylist": widget.controller.categories,
                            });
                        newCategoryCtrl.clear();
                        Get.snackbar("Success", "Category added");
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
