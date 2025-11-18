// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';

import 'package:restaurant_management/Orders/deliverdorder.dart';
import 'package:restaurant_management/Orders/liveorder.dart';
import 'package:restaurant_management/Sales/dailysales.dart';
import 'package:restaurant_management/Sales/monthlysales.dart';
import '../Expenses/daily.dart';
import '../Expenses/monthly.dart';
import '../Product & Admin/Staff/staf.dart';
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
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0A1F44),
            Color(0xFF0C2E69),
            Color(0xFF0F3D85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 14,
            offset: const Offset(5, 0),
          ),
        ],
      ),
      child: ListView(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        children: [
          /// ===== HEADER =====
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Text(
              "Admin Panel",
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ),

          SizedBox(height: 25.h),

          /// ===== MENU ITEMS =====

          _menuTile(
            icon: FontAwesomeIcons.houseChimney,
            title: "Home",
            page: Center(child: Text("Homepage", style: TextStyle(color: Colors.white))),
          ),

          _expansionGroup(
            title: "Orders",
            icon: FontAwesomeIcons.clipboardList,
            children: [
              _menuTile(icon: FontAwesomeIcons.satelliteDish, title: "Live Orders", page: LiveOrdersPage()),
              _menuTile(icon: FontAwesomeIcons.check, title: "Delivered Orders", page: Deliverdorder()),
            ],
          ),

          _menuTile(
            icon: FontAwesomeIcons.chartLine,
            title: "Daily Sales",
            page: const Dailysales(),
          ),

          _menuTile(
            icon: FontAwesomeIcons.chartSimple,
            title: "Monthly Sales",
            page: const Monthlysales(),
          ),

          _menuTile(
            icon: FontAwesomeIcons.peopleGroup,
            title: "Governing Body",
            page: GoverningBodyPage(),
          ),

          _menuTile(
            icon: FontAwesomeIcons.userTie,
            title: "Staff Members",
            page: StaffListPage(),
          ),

          _expansionGroup(
            title: "Expenses",
            icon: FontAwesomeIcons.moneyBillTransfer,
            children: [
              _menuTile(icon: FontAwesomeIcons.calendarDay, title: "Daily Expenses", page: DailyExpensesPage()),
              _menuTile(icon: FontAwesomeIcons.calendarWeek, title: "Monthly Expenses", page: MonthlyExpensesPage()),
            ],
          ),

          _menuTile(
            icon: FontAwesomeIcons.utensils,
            title: "Products",
            page: ProductsPage(),
          ),

          _menuTile(
            icon: FontAwesomeIcons.gift,
            title: "Offers",
            page: Offer(),
          ),
        ],
      ),
    );
  }

  /// ===========================
  /// 🔹 TILE WIDGET
  /// ===========================
  Widget _menuTile({
    required IconData icon,
    required String title,
    required Widget page,
  }) {
    return ListTile(
      leading: FaIcon(icon, color: Colors.white, size: 16.sp),
      title: Text(
        title,
        style: TextStyle(color: Colors.white, fontSize: 14.sp),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
      hoverColor: Colors.white.withOpacity(0.10),
      splashColor: Colors.white24,
      onTap: () => Get.find<Controller>().changePage(page),
    );
  }

  /// ===========================
  /// 🔹 EXPANSION GROUP (Reusable)
  /// ===========================
  Widget _expansionGroup({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Theme(
      data: Theme.of(Get.context!).copyWith(
        dividerColor: Colors.transparent,
      ),
      child: ExpansionTile(
        initiallyExpanded: false,
        iconColor: Colors.cyanAccent,
        collapsedIconColor: Colors.cyanAccent,
        tilePadding: EdgeInsets.symmetric(horizontal: 15.w),
        childrenPadding: EdgeInsets.only(left: 20.w),
        leading: FaIcon(icon, color: Colors.white, size: 16.sp),
        title: Text(
          title,
          style: TextStyle(color: Colors.white, fontSize: 14.sp),
        ),
        children: children,
      ),
    );
  }
}
