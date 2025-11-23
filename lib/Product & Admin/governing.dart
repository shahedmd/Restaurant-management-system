// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:restaurant_management/Product%20&%20Admin/GB/details.dart';

import 'GB/addgb.dart';
import 'GB/controller.dart';

class GoverningBodyPage extends StatelessWidget {
  final GBController controller = Get.put(GBController());

  GoverningBodyPage({super.key});

  @override
  Widget build(BuildContext context) {
    controller.loadBodies();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C2E69),
        centerTitle: true,
        title: Text(
          "Governing Body Members",
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0F3D85),
        child: const FaIcon(FontAwesomeIcons.plus, color: Colors.white),
        onPressed: () => addGBDialog(controller),
      ),
      body: Obx(() {
        if (controller.bodies.isEmpty) {
          return Center(
            child: Text(
              "No Governing Body Found",
              style: TextStyle(fontSize: 16.sp, color: Colors.black54),
            ),
          );
        }

        return ListView.separated(
          padding: EdgeInsets.all(16.w),
          separatorBuilder: (_, __) => SizedBox(height: 12.h),
          itemCount: controller.bodies.length,
          itemBuilder: (_, i) {
            final s = controller.bodies[i];

            return Padding(
              padding:  EdgeInsets.symmetric(horizontal: 40.w, vertical: 20.h),
              child: InkWell(
                mouseCursor: SystemMouseCursors.click,
                onTap: (){
                  Get.to(GBDetailsPage(id: s["id"], name: s["name"]));
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE8F1FF), Color(0xFFDCEBFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.15),
                        blurRadius: 12,
                        spreadRadius: 2,
                        offset: const Offset(2, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Row(
                      children: [
                        /// PROFILE
                        CircleAvatar(
                          radius: 70.r,
                          backgroundColor: Colors.white,
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: s["photo"] ?? "",
                              fit: BoxFit.cover,
                              width: 70.r,
                              height: 70.r,
                              placeholder: (context, url) => Center(
                                child: FaIcon(
                                  FontAwesomeIcons.user,
                                  color: Colors.blueGrey,
                                  size: 28.sp,
                                ),
                              ),
                              errorWidget: (context, url, error) => Center(
                                child: FaIcon(
                                  FontAwesomeIcons.userSlash,
                                  color: Colors.redAccent,
                                  size: 28.sp,
                                ),
                              ),
                            ),
                          ),
                        ),
                
                        SizedBox(width: 16.w),
                
                        /// DETAILS
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// NAME
                              Text(
                                s["name"],
                                style: TextStyle(
                                  fontSize: 17.sp,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0C2E69),
                                ),
                              ),
                              SizedBox(height: 5.h),
                
                              /// DESIGNATION
                              Text(
                                s["des"],
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0C2E69),
                                ),
                              ),
                              SizedBox(height: 6.h),
                
                              /// PHONE
                              detailRow(FontAwesomeIcons.phone, s["phone"]),
                
                              /// NID
                              detailRow(FontAwesomeIcons.idCard, s["nid"]),
                            ],
                          ),
                        ),
                
                        /// ARROW
                        FaIcon(
                          FontAwesomeIcons.angleRight,
                          color: Colors.blueGrey,
                          size: 18.sp,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

/// Reusable row for details
Widget detailRow(IconData icon, String text) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: 3.h),
    child: Row(
      children: [
        FaIcon(icon, size: 14, color: Colors.blueGrey),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.blueGrey, fontSize: 13.sp),
          ),
        ),
      ],
    ),
  );
}
