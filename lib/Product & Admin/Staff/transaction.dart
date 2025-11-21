// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../Expenses/Daily/controller.dart';
import 'controller.dart';

final ExpensesController expensesController = Get.put(ExpensesController());

void addSalaryDialog(
  StaffController controller,
  String staffId,
  String stafname,
) {
  final amountC = TextEditingController();
  final noteC = TextEditingController();
  final monthC = TextEditingController();
  final Rxn<DateTime> selectedDate = Rxn<DateTime>(); // Nullable reactive

  Get.defaultDialog(
    title: "Add Salary",
    titleStyle: TextStyle(
      fontSize: 18.sp,
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    ),
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Amount
        Padding(
          padding: EdgeInsets.symmetric(vertical: 6.h),
          child: TextField(
            controller: amountC,
            keyboardType: TextInputType.number,
            textAlignVertical:
                TextAlignVertical.center, // <-- Fix vertical align
            decoration: InputDecoration(
              prefixIcon: const Padding(
                padding: EdgeInsets.all(12.0), // uniform padding
                child: FaIcon(FontAwesomeIcons.coins, color: Colors.blueAccent),
              ),
              hintText: "Amount",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 14.h,
              ),
            ),
          ),
        ),

        /// Month
        Padding(
          padding: EdgeInsets.symmetric(vertical: 6.h),
          child: TextField(
            controller: monthC,
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              prefixIcon: const Padding(
                padding: EdgeInsets.all(12.0),
                child: FaIcon(
                  FontAwesomeIcons.calendarAlt,
                  color: Colors.blueAccent,
                ),
              ),
              hintText: "Month (e.g. January)",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 14.h,
              ),
            ),
          ),
        ),

        /// Note
        Padding(
          padding: EdgeInsets.symmetric(vertical: 6.h),
          child: TextField(
            controller: noteC,
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              prefixIcon: const Padding(
                padding: EdgeInsets.all(12.0),
                child: FaIcon(
                  FontAwesomeIcons.stickyNote,
                  color: Colors.blueAccent,
                ),
              ),
              hintText: "Note",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 14.h,
              ),
            ),
          ),
        ),

        /// Date Picker
        SizedBox(height: 10.h),
        Obx(
          () => Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.center, // <-- Align vertically
              children: [
                const FaIcon(
                  FontAwesomeIcons.calendarCheck,
                  color: Colors.blueAccent,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    selectedDate.value != null
                        ? DateFormat('dd MMM yyyy').format(selectedDate.value!)
                        : "Pick Salary Date",
                    style: TextStyle(fontSize: 14.sp, color: Colors.black87),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: Get.context!,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      selectedDate.value = picked; // Update reactive variable
                    }
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    minimumSize: Size(0, 0), // remove default min size
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    "Select",
                    style: TextStyle(color: Colors.blueAccent, fontSize: 14.sp),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
    textConfirm: "Save",
    confirmTextColor: Colors.white,
    buttonColor: Colors.blueAccent,
    onConfirm: () async {
      if (amountC.text.isEmpty ||
          monthC.text.isEmpty ||
          selectedDate.value == null) {
        Get.snackbar(
          "Error",
          "Please fill all fields and select a date",
          backgroundColor: Colors.red.shade300,
          colorText: Colors.white,
        );
        return;
      }

      await controller.addSalary(
        staffId,
        double.parse(amountC.text),
        noteC.text,
        monthC.text,
        selectedDate.value!,
      );

      await expensesController.addDailyExpense(
        stafname,
        int.parse(amountC.text),
        note: noteC.text,
        date: selectedDate.value,
      );
      Get.back();
    },
  );
}
