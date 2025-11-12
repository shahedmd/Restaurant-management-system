import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'Custom Elements/items.dart';
import 'controller/menucontroller.dart';

class AdminHomepage extends StatefulWidget {
  const AdminHomepage({super.key});

  @override
  State<AdminHomepage> createState() => _AdminHomepageState();
}

class _AdminHomepageState extends State<AdminHomepage> {
  @override
  Widget build(BuildContext context) {
    final Controller menuController = Get.put(Controller());

    return Scaffold(
      body: Row(
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
                    Center(
                      child: Text(
                        "Welcome to Restaurant Admin Dashboard",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
