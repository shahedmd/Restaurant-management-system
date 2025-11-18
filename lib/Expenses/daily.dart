// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import 'Daily/controller.dart';

class DailyExpensesPage extends StatelessWidget {
  DailyExpensesPage({super.key});

  final ExpensesController controller = Get.put(ExpensesController());

  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController amountCtrl = TextEditingController();
  final TextEditingController noteCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF0C2E69),
        title: Text(
          "Daily Expenses",
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 20.w),
            child: Obx(
              () => IconButton(
                icon: controller.isLoading.value
                    ? SizedBox(
                        width: 24.w,
                        height: 24.w,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const FaIcon(FontAwesomeIcons.filePdf, color: Colors.white),
                onPressed: controller.isLoading.value
                    ? null
                    : () => controller.generateDailyPDF(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0F3D85),
        onPressed: () => showAddDialog(context),
        child: const FaIcon(FontAwesomeIcons.plus, color: Colors.white),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 15.h),

          // Total Display
          Obx(
            () => Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Container(
                width: 400.w,
                padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 16.w),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F3D85), Color(0xFF0A1F44)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(2, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const FaIcon(FontAwesomeIcons.wallet, color: Colors.white),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        "Total: ৳ ${controller.dailyTotal.value}",
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(height: 15.h),

          // Expense List
          Expanded(
            child: Obx(() {
              if (controller.dailyList.isEmpty) {
                return Center(
                  child: Text(
                    "No expenses added today.",
                    style: TextStyle(fontSize: 16.sp, color: Colors.black54),
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: controller.dailyList.length,
                itemBuilder: (context, index) {
                  final item = controller.dailyList[index];
                  final date = item["date"] != null
                      ? DateFormat("dd MMM yyyy")
                          .format(item["date"].toDate())
                      : "";

                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 6.h, horizontal: 150.w),
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(2, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const FaIcon(FontAwesomeIcons.receipt, color: Color(0xFF0C2E69)),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item["name"],
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                "৳ ${item["amount"]} | ${item["note"]}",
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (date.isNotEmpty)
                                Text(
                                  date,
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: Colors.grey[500],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const FaIcon(
                            FontAwesomeIcons.trash,
                            color: Colors.red,
                          ),
                          onPressed: () async {
                            await controller.deleteDaily(item["id"]);
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  void showAddDialog(BuildContext context) {
    nameCtrl.clear();
    amountCtrl.clear();
    noteCtrl.clear();

    final selectedDate = Rx<DateTime?>(null);

    Get.defaultDialog(
      title: "Add Expense",
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Name
          TextField(
            controller: nameCtrl,
            decoration: InputDecoration(
              labelText: "Expense Name",
              prefixIcon: Padding(
                padding: EdgeInsets.only(left: 10.w, right: 10.w),
                child: FaIcon(
                  FontAwesomeIcons.pen,
                  size: 18.sp,
                  color: Colors.grey[700],
                ),
              ),
              prefixIconConstraints:
                  BoxConstraints(minWidth: 40.w, minHeight: 40.h),
            ),
          ),

          SizedBox(height: 8.h),

          // Amount
          TextField(
            controller: amountCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "Amount",
              prefixIcon: Padding(
                padding: EdgeInsets.only(left: 10.w, right: 10.w),
                child: FaIcon(
                  FontAwesomeIcons.coins,
                  size: 18.sp,
                  color: Colors.grey[700],
                ),
              ),
              prefixIconConstraints:
                  BoxConstraints(minWidth: 40.w, minHeight: 40.h),
            ),
          ),

          SizedBox(height: 8.h),

          // Note
          TextField(
            controller: noteCtrl,
            decoration: InputDecoration(
              labelText: "Note",
              prefixIcon: Padding(
                padding: EdgeInsets.only(left: 10.w, right: 10.w),
                child: FaIcon(
                  FontAwesomeIcons.noteSticky,
                  size: 18.sp,
                  color: Colors.grey[700],
                ),
              ),
              prefixIconConstraints:
                  BoxConstraints(minWidth: 40.w, minHeight: 40.h),
            ),
          ),

          SizedBox(height: 12.h),

          // Date picker
          Obx(
            () => ElevatedButton.icon(
              icon: const FaIcon(FontAwesomeIcons.calendar, color: Colors.white),
              label: Text(
                selectedDate.value == null
                    ? "Pick Date"
                    : DateFormat("dd MMM yyyy").format(selectedDate.value!),
                style: const TextStyle(color: Colors.white),
              ),
              onPressed: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) selectedDate.value = picked;
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F3D85),
              ),
            ),
          ),
        ],
      ),
      textConfirm: "Add",
      onConfirm: () async {
        if (nameCtrl.text.isEmpty || amountCtrl.text.isEmpty) return;

        await controller.addDailyExpense(
          nameCtrl.text,
          int.parse(amountCtrl.text),
          note: noteCtrl.text,
          date: selectedDate.value ?? DateTime.now(),
        );

        Get.back();
      },
    );
  }
}
