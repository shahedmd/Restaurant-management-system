import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'Menu/controller.dart';
import 'Offer/addofferdialog,.dart';
import 'Offer/offercard.dart';

class Offer extends StatelessWidget {
  Offer({super.key});

  final MenuGetxCtrl controller = Get.put(MenuGetxCtrl());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddOfferDialog(context, controller),
        child: const Icon(Icons.add),
      ),

      appBar: AppBar(
        centerTitle: true,
        title: const Text("Offers", style: TextStyle(color: Colors.white),),
        backgroundColor: const Color.fromARGB(255, 2, 41, 87),
      ),

      body: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            SizedBox(height: 25.h),
        
            // ---------------- SEARCH BAR ----------------
            SizedBox(
              width: 400.w,
              child: TextField(
                onChanged: (value) {
                  controller.searchQuery.value = value;
                  controller.applyFilter();
                },
                decoration: InputDecoration(
                  hintText: "Search offers…",
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
        
            // ---------------- CONTENT ----------------
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(15.0.r),
                child: StreamBuilder(
                  stream: controller.fetchItems(collection: "offers"),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
        
                    return Obx(() {
                      final list = controller.filteredItems;
        
                      if (list.isEmpty) {
                        return Center(
                          child: Text(
                            "No offers found",
                            style: TextStyle(fontSize: 16.sp),
                          ),
                        );
                      }
        
                      return SingleChildScrollView(
                        child: Wrap(
                          spacing: 20.w,
                          runSpacing: 20.h,
                          children: list.map((doc) {
                            return offerCard(context, doc, controller);
                          }).toList(),
                        ),
                      );
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
