import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'GB/addgb.dart';
import 'GB/controller.dart';
import 'GB/details.dart';

class GoverningBodyPage extends StatelessWidget {
  final controller = Get.put(GBController());

   GoverningBodyPage({super.key});

  @override
  Widget build(BuildContext context) {
    controller.loadBodies();

    return Scaffold(
      appBar: AppBar(title: Text("Governing Body List")),

      floatingActionButton: FloatingActionButton(
        onPressed: () => addGBDialog(controller),
        child: Icon(Icons.add),
      ),

      body: Obx(() {
        if (controller.bodies.isEmpty) {
          return Center(child: Text("No Governing Body Found"));
        }

        return ListView.builder(
          itemCount: controller.bodies.length,
          itemBuilder: (context, index) {
            final item = controller.bodies[index];

            return Card(
              child: ListTile(
                title: Text(item["name"]),
                subtitle: Text(item["phone"]),
                onTap: () => Get.to(() => GBDetailsPage(id: item["id"], name: item["name"])),
              ),
            );
          },
        );
      }),
    );
  }
}
