// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
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
  final int price = data["price"];
  final DateTime validate = data["validate"].toDate();

  return Container(
    width: 180.w,
    padding:  EdgeInsets.all(12.r),
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
        // IMAGE
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            img,
            width: double.infinity,
            height: 190.h,
            fit: BoxFit.cover,
          ),
        ),

         SizedBox(height: 10.h),

        // NAME
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style:  TextStyle(
            fontSize: 17.sp,
            fontWeight: FontWeight.w600,
          ),
        ),

         SizedBox(height: 5.h),

        // PRICE
        Text(
          "৳ $price",
          style:  TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),

         SizedBox(height: 6.h),

        // VALID DATE
        Text(
          "Valid till: ${validate.toString().split(" ")[0]}",
          style:  TextStyle(
            fontSize: 14.sp,
            color: Colors.orange,
          ),
        ),

         SizedBox(height: 10.h),

        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // EDIT BUTTON
            InkWell(
              onTap: () => showEditOfferDialog(context, doc, controller),
              child:  Icon(Icons.edit, color: Colors.blue, size: 22.r),
            ),

             SizedBox(width: 12.w),

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
                    onPressed: () {
                      controller.deleteItem(
                        docId: doc.id,
                        collection: "offers",
                      );
                      Get.back();
                    },
                    child: const Text("Delete"),
                  ),
                );
              },
              child:  Icon(Icons.delete, color: Colors.red, size: 22.r),
            ),
          ],
        ),
      ],
    ),
  );
}
