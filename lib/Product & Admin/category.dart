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

  /// Save changes to Firestore
  Future<void> _updateFirestore() async {
    await db.collection("category").doc("VPSKqsQRbOLyz1aOloSG").update({
      "categorylist": widget.controller.categories,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Manage Categories",
          style: TextStyle(color: Colors.white),
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
                          // Category Name
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
                                widget.controller.categories[index] = val.trim();
                                await _updateFirestore();
                                Get.snackbar("Success", "Category updated");
                              },
                            ),
                          ),
                          SizedBox(width: 6.w),

                          // Move Up
                          IconButton(
                            onPressed: index > 0
                                ? () async {
                                    final temp =
                                        widget.controller.categories[index - 1];
                                    widget.controller.categories[index - 1] =
                                        widget.controller.categories[index];
                                    widget.controller.categories[index] = temp;
                                    await _updateFirestore();
                                  }
                                : null,
                            icon: Icon(FontAwesomeIcons.arrowUp,
                                size: 16.sp,
                                color: index > 0
                                    ? Colors.blue.shade700
                                    : Colors.grey),
                          ),

                          // Move Down
                          IconButton(
                            onPressed: index < widget.controller.categories.length - 1
                                ? () async {
                                    final temp =
                                        widget.controller.categories[index + 1];
                                    widget.controller.categories[index + 1] =
                                        widget.controller.categories[index];
                                    widget.controller.categories[index] = temp;
                                    await _updateFirestore();
                                  }
                                : null,
                            icon: Icon(FontAwesomeIcons.arrowDown,
                                size: 16.sp,
                                color: index < widget.controller.categories.length - 1
                                    ? Colors.blue.shade700
                                    : Colors.grey),
                          ),

                          // Delete
                          InkWell(
                            onTap: () async {
                              widget.controller.categories.removeAt(index);
                              await _updateFirestore();
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
                        await _updateFirestore();
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
