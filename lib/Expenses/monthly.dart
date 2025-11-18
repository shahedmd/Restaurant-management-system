// ignore_for_file: use_super_parameters, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import 'Monthly/controller.dart';

class MonthlyExpensesPage extends StatelessWidget {
  MonthlyExpensesPage({Key? key}) : super(key: key);

  final MonthlyExpensesController controller = Get.put(MonthlyExpensesController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C2E69),
        title: Text(
          'Monthly Expenses',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: Obx(() {
        if (controller.monthlyList.isEmpty) {
          return Center(
            child: Text(
              'No monthly expenses found.',
              style: TextStyle(fontSize: 16.sp, color: Colors.black54),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          itemCount: controller.monthlyList.length,
          itemBuilder: (context, index) {
            final month = controller.monthlyList[index];
            final monthKey = month['month'];

            return Container(
              margin: EdgeInsets.symmetric(vertical: 6.h),
              padding: EdgeInsets.all(12.w),
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
                    blurRadius: 6,
                    offset: const Offset(2, 4),
                  ),
                ],
              ),
              child: ListTile(
                title: Text(
                  monthKey,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                subtitle: Text(
                  'Total: BDT ${month['total']}',
                  style: TextStyle(fontSize: 14.sp, color: Colors.white70),
                ),
                trailing: Obx(
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
                        : () => controller.generateMonthlyPDF(monthKey),
                  ),
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text('Expenses for $monthKey'),
                      content: SizedBox(
                        width: 600.w,
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: (month['items'] as List).length,
                          separatorBuilder: (_, __) => Divider(color: Colors.grey[300]),
                          itemBuilder: (_, idx) {
                            final item = month['items'][idx];
                            final formattedDate = DateFormat('dd MMM yyyy').format(
                              DateTime.parse(item['date']),
                            );

                            return ListTile(
                              leading: const FaIcon(
                                FontAwesomeIcons.calendarDays,
                                color: Color(0xFF0C2E69),
                              ),
                              title: Text(formattedDate),
                              trailing: Text(
                                '৳ ${item['total']}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  fontSize: 14.sp,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Get.back(),
                          child: const Text('Close'),
                        )
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      }),
    );
  }
}
