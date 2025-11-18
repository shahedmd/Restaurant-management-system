// ignore_for_file: deprecated_member_use

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:restaurant_management/Product%20&%20Admin/Staff/details.dart';

import 'addstaff.dart';
import 'controller.dart';

class StaffListPage extends StatelessWidget {
  final StaffController controller = Get.put(StaffController());

  StaffListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),

      appBar: AppBar(
        backgroundColor: const Color(0xFF0C2E69),
        centerTitle: true,
        elevation: 0,
        title: Text(
          "Staff Members",
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0F3D85),
        child:  FaIcon(FontAwesomeIcons.plus, color: Colors.white,),
        onPressed: () => addStaffDialog(controller),
      ),

      body: Obx(() {
        if (controller.staffList.isEmpty) {
          return Center(
            child: Text(
              "No Staff Found",
              style: TextStyle(fontSize: 16.sp, color: Colors.black54),
            ),
          );
        }

        return ListView.separated(
          padding: EdgeInsets.all(16.w),
          itemCount: controller.staffList.length,
          separatorBuilder: (_, __) => SizedBox(height: 12.h),

          itemBuilder: (_, i) {
            final s = controller.staffList[i];

            final joinDate = DateFormat(
              "dd MMM yyyy",
            ).format(s['joiningDate'].toDate());

            return Padding(
              padding:  EdgeInsets.symmetric(horizontal: 25.w, vertical: 10.h),
              child: InkWell(
                mouseCursor: SystemMouseCursors.click,
              
                onTap: () {
                  Get.to(StaffDetailsPage(staffId: s["id"], name: s["name"]));
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [const Color(0xFFE8F1FF), const Color(0xFFDCEBFF)],
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
              
                              /// SHOW LOADING ICON
                              placeholder:
                                  (context, url) => Center(
                                    child: FaIcon(
                                      FontAwesomeIcons.user,
                                      color: Colors.blueGrey,
                                      size: 28.sp,
                                    ),
                                  ),
              
                              /// SHOW ERROR ICON
                              errorWidget:
                                  (context, url, error) => Center(
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

                              SizedBox(height: 5.h,),
                                Text(
                                s["des"],
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0C2E69),
                                ),
                              ),
              
                              SizedBox(height: 6.h),
              
                              detailRow(
                                FontAwesomeIcons.calendarDay,
                                "Joined: $joinDate",
                              ),
                              detailRow(FontAwesomeIcons.phone, s["phone"]),
                              detailRow(
                                FontAwesomeIcons.idCard,
                                "NID: ${s['nid']}",
                              ),
                              Row(
                                children: [
                                  FaIcon(
                                    Icons.money,
                                    size: 12,
                                    color: Color(0xFF4A6FA8),
                                  ),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: Text(
                                      "Salary : ${s["salary"]}",
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF4A6FA8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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

Widget detailRow(IconData icon, String text) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: 3.h),
    child: Row(
      children: [
        FaIcon(icon, size: 12, color: Color(0xFF4A6FA8)),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12.sp, color: Color(0xFF4A6FA8)),
          ),
        ),
      ],
    ),
  );
}
