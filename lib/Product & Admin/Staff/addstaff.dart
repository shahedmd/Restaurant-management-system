import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import 'controller.dart';

void addStaffDialog(StaffController controller) {
  final nameC = TextEditingController();
  final phoneC = TextEditingController();
  final nidC = TextEditingController();
  final desC = TextEditingController();
  final salaryC = TextEditingController();

  final Rx<DateTime?> joiningDate = Rx<DateTime?>(null); // reactive date

  Get.defaultDialog(
    title: "Add Staff Member",
    radius: 12.r,
    titleStyle: TextStyle(
      fontSize: 18.sp,
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    ),
    content: SizedBox(
      width: 350.w,
      child: Column(
        children: [
          buildField(nameC, "Full Name", FontAwesomeIcons.user),
          buildField(phoneC, "Phone Number", FontAwesomeIcons.phone),
          buildField(nidC, "NID No", FontAwesomeIcons.idCard),
          buildField(desC, "Designation", FontAwesomeIcons.briefcase),
          buildField(salaryC, "Salary (Tk)", FontAwesomeIcons.coins,
              type: TextInputType.number),
          SizedBox(height: 14.h),

          /// ✅ Reactive Joining Date Button
          Obx(
            () => SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                icon: FaIcon(FontAwesomeIcons.calendarDay, size: 14.sp),
                label: Text(
                  joiningDate.value != null
                      ? DateFormat("dd MMM yyyy").format(joiningDate.value!)
                      : "Choose Joining Date",
                  style: TextStyle(
                      fontSize: 14.sp, fontWeight: FontWeight.w500),
                ),
                onPressed: () async {
                  DateTime? picked = await showDatePicker(
                    context: Get.context!,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    joiningDate.value = picked; // reactive update
                  }
                },
              ),
            ),
          ),
        ],
      ),
    ),
    textConfirm: "Save",
    confirmTextColor: Colors.white,
    buttonColor: Colors.blue,
    onConfirm: () {
      if (nameC.text.isEmpty ||
          phoneC.text.isEmpty ||
          nidC.text.isEmpty ||
          desC.text.isEmpty ||
          salaryC.text.isEmpty ||
          joiningDate.value == null) {
        Get.snackbar("Error", "Please fill all fields and select date");
        return;
      }

      controller.addStaff(
        name: nameC.text,
        phone: phoneC.text,
        nid: nidC.text,
        des: desC.text,
        salary: int.parse(salaryC.text),
        joinDate: joiningDate.value!,
      );
      Get.back();
    },
  );
}


Widget buildField(
  TextEditingController c,
  String hint,
  IconData icon, {
  TextInputType type = TextInputType.text,
}) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: 6.h),
    child: TextField(
      controller: c,
      keyboardType: type,
      style: TextStyle(fontSize: 14.sp),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey.shade100,

        prefixIcon: Padding(
          padding: EdgeInsets.all(12.w), // keeps icon perfectly centered
          child: FaIcon(icon, size: 16.sp, color: Colors.blueGrey),
        ),

        hintText: hint,
        hintStyle: TextStyle(fontSize: 13.sp, color: Colors.grey),

        contentPadding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 12.w),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide.none,
        ),
      ),
    ),
  );
}
