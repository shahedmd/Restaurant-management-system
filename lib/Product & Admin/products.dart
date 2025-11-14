// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:restaurant_management/Product & Admin/Menu/controller.dart';

import 'Menu/dialog.dart';
import 'Menu/editdialog.dart';
import 'Menu/model.dart';

class ProductsPage extends StatelessWidget {
  ProductsPage({super.key});

  final MenuGetxCtrl controller = Get.put(MenuGetxCtrl());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => showCreateMenuDialog(context),
        child: const Icon(Icons.add),
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 30.h),

          // ---------------- Search Bar ----------------
          SizedBox(
            width: 400.w,
            child: TextField(
              onChanged: (value) {
                controller.searchQuery.value = value;
                controller.applyFilter();    
              },
              decoration: InputDecoration(
                hintText: "Search items…",
                hintStyle: TextStyle(fontSize: 14.sp, color: Colors.grey),
                prefixIcon: Icon(Icons.search, size: 22.sp, color: Colors.grey),

                contentPadding: EdgeInsets.symmetric(
                  vertical: 12.h,
                  horizontal: 15.w,
                ),

                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: Colors.grey.shade300,
                    width: 1.w,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: Colors.blue, width: 1.2.w),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
          ),

          SizedBox(height: 20.h),

          // STREAM fetch updates filtered list
          StreamBuilder(
            stream: controller.fetchItems(collection: "menu"),
            builder: (context, snapshot) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.all(15.w),

                  // ---------------- FILTERED UI ----------------
                  child: Obx(() {
                    final list = controller.filteredItems;

                    if (list.isEmpty) {
                      return Center(
                        child: Text(
                          "No items found",
                          style: TextStyle(fontSize: 16.sp),
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      child: Wrap(
                        spacing: 15.w,
                        runSpacing: 15.h,
                        children: list.map((doc) {
                          final item =
                              MenuItemModel.fromDoc(doc); // convert only here
                          return _menuCard( doc, item);
                        }).toList(),
                      ),
                    );
                  }),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ---------------- MENU CARD ----------------
  Widget _menuCard(QueryDocumentSnapshot doc, MenuItemModel item) {
  final MenuGetxCtrl controller = Get.find();

  return Container(
    width: 180.w,
    padding: EdgeInsets.all(10.w),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12.r),
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 6.r,
          offset: Offset(0, 3.h),
        ),
      ],
    ),
    child: Stack(
      children: [
        // ---------------- PRODUCT CONTENT ----------------
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10.r),
              child: Image.network(
                item.imgUrl,
                height: 180.h,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              item.name,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            Text(
              item.category,
              style: TextStyle(fontSize: 14.sp, color: Colors.grey),
            ),
            SizedBox(height: 5.h),
            Text(
              "৳ ${item.price}",
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
          ],
        ),

        // ---------------- EDIT & DELETE BUTTONS ----------------
        Positioned(
          top: 0,
          right: 0,
          child: Row(
            children: [
              // Edit button
              InkWell(
                onTap: () => showEditMenuDialog(Get.context!, doc),
                child: Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.edit, size: 18.sp, color: Colors.white),
                ),
              ),
              SizedBox(width: 5.w),
              // Delete button
              InkWell(
                onTap: () async {
                  bool confirm = await showDialog(
                    context: Get.context!,
                    builder: (context) => AlertDialog(
                      title: const Text("Confirm Delete"),
                      content: const Text("Are you sure you want to delete this item?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Cancel"),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text("Delete"),
                        ),
                      ],
                    ),
                  );
                  if (confirm) {
                    await controller.deleteItem(collection: "menu", docId :  doc.id); // call delete function
                  }
                },
                child: Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.delete, size: 18.sp, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

}