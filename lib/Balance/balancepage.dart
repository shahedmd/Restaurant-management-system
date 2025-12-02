// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'controller.dart';

class BalancePage extends StatelessWidget {
  final BalanceController ctrl = Get.put(BalanceController());
  final NumberFormat currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: 'BDT');

  BalancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Monthly Balance"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.r),
        child: Obx(() {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Month Selector
              Row(
                children: [
                  Text("Select Month: ", style: TextStyle(fontSize: 16.sp)),
                  SizedBox(width: 10.w),
                  DropdownButton<String>(
                    value: ctrl.selectedMonth.value,
                    items: ctrl.availableMonths
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (v) => ctrl.selectedMonth.value = v ?? ctrl.selectedMonth.value,
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // Grid summary cards
              GridView.count(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.5,
                children: [
                  _card("Total Sales", currencyFormat.format(ctrl.totalSales.value), Colors.green),
                  _card("Total Expenses", currencyFormat.format(ctrl.totalExpenses.value), Colors.red),
                  _card("Net Profit", currencyFormat.format(ctrl.netProfit.value), Colors.blue),
                  _card("Restaurant Saving", currencyFormat.format(ctrl.restaurantSaving.value), Colors.orange),
                ],
              ),
              SizedBox(height: 20.h),

              // Governing body distribution
              Text("Governing Body Distribution", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 10.h),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: ctrl.governingBodyShares.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final gb = ctrl.governingBodyShares[index];
                  return ListTile(
                    title: Text(gb['name']),
                    subtitle: Text("Share: ${gb['share']}%"),
                    trailing: Text(currencyFormat.format(gb['amount']), style: const TextStyle(fontWeight: FontWeight.bold)),
                  );
                },
              ),
            ],
          );
        }),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _exportPdf,
        child: const Icon(Icons.picture_as_pdf),
      ),
    );
  }

  Widget _card(String title, String amount, Color color) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(amount, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _exportPdf() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text("Monthly Balance Report (${ctrl.selectedMonth.value})", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 20),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("Total Sales: ${currencyFormat.format(ctrl.totalSales.value)}"),
              pw.Text("Total Expenses: ${currencyFormat.format(ctrl.totalExpenses.value)}"),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("Net Profit: ${currencyFormat.format(ctrl.netProfit.value)}"),
              pw.Text("Restaurant Saving: ${currencyFormat.format(ctrl.restaurantSaving.value)}"),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Text("Governing Body Distribution:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 5),
          pw.Table.fromTextArray(
            headers: ["Name", "Share %", "Amount"],
            data: ctrl.governingBodyShares.map((e) => [e['name'], e['share'].toString(), currencyFormat.format(e['amount'])]).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }
}
