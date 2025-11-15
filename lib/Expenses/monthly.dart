// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'Monthly/controller.dart';

class MonthlyExpensesPage extends StatelessWidget {
  MonthlyExpensesPage({Key? key}) : super(key: key);

  final MonthlyExpensesController controller = Get.put(MonthlyExpensesController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.monthlyList.isEmpty) {
          return const Center(child: Text('No monthly expenses found.'));
        }

        return ListView.builder(
          itemCount: controller.monthlyList.length,
          itemBuilder: (context, index) {
            final month = controller.monthlyList[index];
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 15.w, vertical: 8.h),
              child: ListTile(
                title: Text(month['month'], style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
                subtitle: Text('Total: BDT ${month['total']}'),
                trailing: IconButton(
                  icon: const Icon(Icons.picture_as_pdf),
                  onPressed: () => controller.generateMonthlyPDF(month['month']),
                ),
                onTap: () {
                  // Optional: show a dialog or page with all daily expenses for that month
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text('Expenses for ${month['month']}'),
                      content: SizedBox(
                        width: double.maxFinite,
                        child: ListView(
                          shrinkWrap: true,
                          children: (month['items'] as List).map<Widget>((e) {
                            return ListTile(
                              title: Text(e['date']),
                              trailing: Text('৳ ${e['total']}'),
                            );
                          }).toList(),
                        ),
                      ),
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
