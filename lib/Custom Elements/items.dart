// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:restaurant_management/Orders/deliverdorder.dart';
import 'package:restaurant_management/Orders/liveorder.dart';
import 'package:restaurant_management/Sales/dailysales.dart';
import 'package:restaurant_management/Sales/monthlysales.dart';
import '../Expenses/daily.dart';
import '../Expenses/monthly.dart';
import '../Product & Admin/governing.dart';
import '../Product & Admin/offer.dart';
import '../Product & Admin/products.dart';
import '../controller/menucontroller.dart';

class SidebarMenu extends StatelessWidget {
  SidebarMenu({super.key});

  final Controller menuController = Get.put(Controller());

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250.w,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: ListView(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        children: [
          /// Logo / Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Text(
              "Admin Panel",
              style: TextStyle(
                fontSize: 20.sp,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          SizedBox(height: 20.h),
          _menuTile(
            "🏠  Home",
            Center(
              child: Text("Homepage", style: TextStyle(color: Colors.white)),
            ),
          ),
          ExpansionTile(
            title: Text(
              "🧾  Orders",
              style: TextStyle(color: Colors.white, fontSize: 14.sp),
            ),
            childrenPadding: EdgeInsets.only(left: 20.w),
            iconColor: Colors.cyanAccent,
            collapsedIconColor: Colors.cyanAccent,
            children: [
              _menuTile("📡 Live Orders",  LiveOrdersPage()),
              _menuTile("✅ Delivered Orders",  Deliverdorder()),
            ],
          ),
          _menuTile("📈 Daily Sales", const Dailysales()),
          _menuTile("📊 Monthly Sales", const Monthlysales()),
          _menuTile("🏛 Governing Body", const GoverningBodyPage()),
          ExpansionTile(
            title: Text(
              "💰 Expenses",
              style: TextStyle(color: Colors.white, fontSize: 14.sp),
            ),
            iconColor: Colors.cyanAccent,
            collapsedIconColor: Colors.cyanAccent,
            childrenPadding: EdgeInsets.only(left: 20.w),
            children: [
              _menuTile("📆 Daily Expenses", const DailyExpensesPage()),
              _menuTile("📅 Monthly Expenses", const MonthlyExpensesPage()),
            ],
          ),
          _menuTile("🍽 Products",  ProductsPage()),
          _menuTile("🎁 Offers",  Offer()),
        ],
      ),
    );
  }

  Widget _menuTile(String title, Widget page) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(color: Colors.white, fontSize: 14.sp),
      ),
      hoverColor: Colors.cyanAccent.withOpacity(0.2),
      onTap: () =>Get.find<Controller>().changePage(page),
    );
  }
}
