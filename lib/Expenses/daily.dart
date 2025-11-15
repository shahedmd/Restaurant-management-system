// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

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
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => showAddDialog(context),
      ),
      body: Column(
        children: [
          SizedBox(height: 10.h),

          // Total display
          Obx(() => Padding(
                padding: EdgeInsets.symmetric(horizontal: 15.w),
                child: Text(
                  "Total: ৳ ${controller.dailyTotal.value}",
                  style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
                ),
              )),

          SizedBox(height: 20.h),

          // PDF button
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.w),
            child: Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text("Download PDF"),
                onPressed: () => controller.generateDailyPDF(),
              ),
            ),
          ),

          SizedBox(height: 10.h),

          // List of expenses (fully reactive)
          Expanded(
            child: Obx(() {
              if (controller.dailyList.isEmpty) {
                return const Center(
                  child: Text(
                    "No expenses added today.",
                    style: TextStyle(fontSize: 16),
                  ),
                );
              }

              return ListView.builder(
                itemCount: controller.dailyList.length,
                itemBuilder: (context, index) {
                  final item = controller.dailyList[index];
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 15.w, vertical: 8.h),
                    child: ListTile(
                      title: Text(
                        item["name"],
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text("৳ ${item["amount"]} | ${item["note"]}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await controller.deleteDaily(item["id"]);
                        },
                      ),
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Expense"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Expense Name"),
            ),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Amount"),
            ),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(labelText: "Note"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty || amountCtrl.text.isEmpty) return;

              // Auto-save to daily and monthly
              await controller.addDailyExpense(
                nameCtrl.text,
                int.parse(amountCtrl.text),
                note: noteCtrl.text,
              );

              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }
}
