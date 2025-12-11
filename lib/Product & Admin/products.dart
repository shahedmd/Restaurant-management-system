// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'Menu/controller.dart';
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
        backgroundColor: Colors.blue.shade800,
        onPressed: () => showCreateMenuDialog(context),
        child: Icon(Icons.add, color: Colors.white),
      ),

      appBar: AppBar(
        centerTitle: true,
        title: const Text("Our Menu", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 2, 41, 87),
      ),

      body: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            SizedBox(height: 25.h),
        
            SizedBox(
              width: 400.w,
              child: TextField(
                onChanged: (value) {
                  controller.searchQuery.value = value;
                  controller.applyFilter();
                },
                decoration: InputDecoration(
                  hintText: "Search items…",
                  prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20.sp),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 14.h,
                    horizontal: 16.w,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    borderSide: const BorderSide(color: Colors.blue),
                  ),
                ),
              ),
            ),
        
            SizedBox(height: 20.h),
        
            /// 📡 STREAM + OBSERVER
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: controller.fetchItems(collection: "menu"),
                builder: (context, snapshot) {
                  return Obx(() {
                    final list = controller.filteredItems;
                    
        
                    if (list.isEmpty) {
                      return Center(
                        child: Text(
                          "No items found",
                          style: TextStyle(fontSize: 16.sp),
                        ),
                      );
                    }
        
                    return Center(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Padding(
                          padding: EdgeInsets.all(16.w),
                          child: Wrap(
                            spacing: 20.w,
                            runSpacing: 20.h,
                            children: List.generate(list.length, (i) {
                              final doc = list[i];
                              final item = MenuItemModel.fromDoc(
                                doc.data() as Map<String, dynamic>,
                              );
                              return _menuCard(doc, item, context);
                            }),
                          ),
                        ),
                      ),
                    );
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🍱 MENU CARD (WRAP STYLE)
  Widget _menuCard(
    QueryDocumentSnapshot doc,
    MenuItemModel item,
    BuildContext context,
  ) {
    final MenuGetxCtrl controller = Get.find();

    final displayPrice = item.selectedVariant?.price ?? item.price ?? 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      width: 185.w,
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🖼 CACHED IMAGE WITH ROUNDED CORNERS
              ClipRRect(
                borderRadius: BorderRadius.circular(14.r),
                child: CachedNetworkImage(
                  imageUrl: item.imgUrl,
                  height: 200.h,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder:
                      (_, __) =>
                          Container(height: 200.h, color: Colors.grey.shade200),
                  errorWidget:
                      (_, __, ___) => Container(
                        height: 200.h,
                        color: Colors.grey.shade300,
                        alignment: Alignment.center,
                        child: const Icon(Icons.error, color: Colors.red),
                      ),
                ),
              ),

              SizedBox(height: 10.h),

              Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),

              Text(
                item.category,
                style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade600),
              ),

              SizedBox(height: 6.h),

              Text(
                item.variants != null && item.variants!.isNotEmpty
                    ? "From: ৳ ${item.variants!.map((v) => v.price).reduce((a, b) => a < b ? a : b)}"
                    : "৳ $displayPrice",
                style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          /// ✏ DELETE & EDIT
          Positioned(
            top: 0,
            right: 0,
            child: Row(
              children: [
                /// ✏ EDIT
                InkWell(
                  onTap: () => showEditMenuDialog(Get.context!, doc),
                  child: Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      shape: BoxShape.circle,
                    ),
                    child: FaIcon(
                      FontAwesomeIcons.penToSquare,
                      color: Colors.white,
                      size: 14.sp,
                    ),
                  ),
                ),
                SizedBox(width: 5.w),

                /// 🗑 DELETE
                InkWell(
                  onTap: () async {
                    bool confirm = await showDialog(
                      context: Get.context!,
                      builder:
                          (_) => AlertDialog(
                            title: const Text("Confirm Delete"),
                            content: const Text(
                              "Do you want to delete this item?",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text("Cancel"),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text("Delete"),
                              ),
                            ],
                          ),
                    );

                    if (confirm == true) {
                      await controller.deleteItem(
                        collection: "menu",
                        docId: doc.id,
                      );
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: FaIcon(
                      FontAwesomeIcons.trash,
                      color: Colors.white,
                      size: 14.sp,
                    ),
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
