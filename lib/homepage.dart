import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:restaurant_management/Expenses/Monthly/controller.dart';

import 'Custom Elements/items.dart';
import 'controller/menucontroller.dart';
import 'over.dart';

class AdminHomepage extends StatefulWidget {
  const AdminHomepage({super.key});

  @override
  State<AdminHomepage> createState() => _AdminHomepageState();
}

class _AdminHomepageState extends State<AdminHomepage> {
  @override
  Widget build(BuildContext context) {
    final Controller menuController = Get.put(Controller());
    final MonthlyExpensesController _ = Get.put(MonthlyExpensesController());

    return Scaffold(
      body: SizedBox(
        child: Row(
          children: [
            SidebarMenu(),
        
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white10
                ),
                child: Obx(
                  () =>
                      menuController.selectedPage.value ??
                     TodayOverviewPage()
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
