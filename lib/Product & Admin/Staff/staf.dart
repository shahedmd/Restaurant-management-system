import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'addstaff.dart';
import 'controller.dart';
import 'details.dart';


class StaffListPage extends StatelessWidget {
  final controller = Get.put(StaffController());

   StaffListPage({super.key});

  @override
  Widget build(BuildContext context) {
    controller.loadStaff();

    return Scaffold(
      appBar: AppBar(title: Text("Staff List")),

      floatingActionButton: FloatingActionButton(
        onPressed: () => addStaffDialog(controller),
        child: Icon(Icons.add),
      ),

      body: Obx(() {
        if (controller.staffList.isEmpty) {
          return Center(child: Text("No Staff Found"));
        }

        return ListView.builder(
          itemCount: controller.staffList.length,
          itemBuilder: (_, i) {
            final s = controller.staffList[i];

            return Card(
              child: ListTile(
                title: Text(s["name"]),
                subtitle:
                    Text("Joined: ${s['joiningDate'].toDate().toString().split(' ').first}"),
                onTap: () => Get.to(
                  () => StaffDetailsPage(
                    staffId: s["id"],
                    name: s["name"],
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
