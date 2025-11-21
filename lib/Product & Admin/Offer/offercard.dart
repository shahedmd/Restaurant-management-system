// ignore_for_file: deprecated_member_use
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../Menu/controller.dart';
import 'editoffers.dart';

Widget offerCard(
  BuildContext context,
  QueryDocumentSnapshot doc,
  MenuGetxCtrl controller,
) {
  final data = doc.data() as Map<String, dynamic>;
  final String img = data["imgUrl"];
  final String name = data["name"];
  final int? price = data["price"];
  final DateTime validate = data["validate"].toDate();
  final formattedDate = DateFormat('dd MMM yyyy').format(validate);

  // Variants (if any)
  List<Map<String, dynamic>> variants = [];
  if (data.containsKey("variants") && data["variants"] is List) {
    variants = List<Map<String, dynamic>>.from(data["variants"]);
  }

  return Container(
    width: 180.w,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 6,
          offset: const Offset(0, 3),
        )
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // IMAGE WITH ICONS STACK
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: img,
                width: double.infinity,
                height: 190.h,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: 190.h,
                  color: Colors.blue.withOpacity(0.08),
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (_, __, ___) => Container(
                  height: 190.h,
                  color: Colors.grey.shade200,
                  child: Icon(Icons.broken_image, size: 30.sp, color: Colors.grey),
                ),
              ),
            ),
            Positioned(
              top: 8.h,
              right: 8.w,
              child: Row(
                children: [
                  // EDIT BUTTON
                  InkWell(
                    onTap: () => showEditOfferDialog(context, doc, controller),
                    child: Container(
                      padding: EdgeInsets.all(6.w),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(FontAwesomeIcons.penToSquare, color: Colors.blue.shade700, size: 18.sp),
                    ),
                  ),
                  SizedBox(width: 6.w),
                  // DELETE BUTTON
                  InkWell(
                    onTap: () {
                      Get.defaultDialog(
                        title: "Delete Offer?",
                        middleText: "Are you sure you want to delete this offer?",
                        cancel: TextButton(
                          onPressed: () => Get.back(),
                          child: const Text("Cancel"),
                        ),
                        confirm: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () {
                            controller.deleteItem(docId: doc.id, collection: "offers");
                            Get.back();
                          },
                          child: const Text("Delete"),
                        ),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.all(6.w),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(FontAwesomeIcons.trash, color: Colors.red.shade700, size: 18.sp),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        SizedBox(height: 10.h),

        // NAME
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 17.sp,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade900,
            ),
          ),
        ),

        SizedBox(height: 5.h),

        // PRICE OR VARIANTS
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: variants.isEmpty
              ? Text(
                  "৳ $price",
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: variants.map((v) {
                    return Text(
                      "${v['size']} : ৳${v['price']}",
                      style: TextStyle(fontSize: 15.sp, color: Colors.green.shade700),
                    );
                  }).toList(),
                ),
        ),

        SizedBox(height: 6.h),

        // VALID DATE
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: Text(
            "Valid till: $formattedDate",
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.orange.shade700,
            ),
          ),
        ),

        SizedBox(height: 10.h),
      ],
    ),
  );
}
