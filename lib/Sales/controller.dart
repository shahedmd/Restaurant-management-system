// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class SalesController extends GetxController {
  RxBool isLoading = false.obs;

  /// Add a sale to Firestore
  Future<void> addSale(
    Map<String, dynamic> order,
    String docId,
    String? customerName,
    String? customerPhone,
  ) async {
    try {
      final num total = (order['total'] ?? 0) as num;

      final String name = customerName?.toString() ?? "Unknown";
      final String phone = customerPhone?.toString() ?? "Unknown";
      final String paymentMethod = order['paymentMethod']?.toString() ?? "Unknown";
      final String status = order['status']?.toString() ?? "Completed";
      final List items = order['items'] is List ? order['items'] as List : [];

      // Use order timestamp for daily/monthly ID
      final Timestamp orderTime =
          order['timestamp'] is Timestamp ? order['timestamp'] : Timestamp.now();
      final DateTime orderDate = orderTime.toDate();

      final String dailyId = DateFormat('yyyy-MM-dd').format(orderDate);
      final String monthlyId = DateFormat('yyyy-MM').format(orderDate);

      final dailyRef = FirebaseFirestore.instance.collection('dailySales').doc(dailyId);
      final monthlyRef = FirebaseFirestore.instance.collection('monthlySales').doc(monthlyId);

      final saleData = {
        'name': name,
        'phone': phone,
        'total': total,
        'timestamp': orderTime,
        'orderId': docId,
        'items': items,
        'paymentMethod': paymentMethod,
        'status': status,
      };

      await dailyRef.set({'orders': FieldValue.arrayUnion([saleData])}, SetOptions(merge: true));
      await monthlyRef.set({'orders': FieldValue.arrayUnion([saleData])}, SetOptions(merge: true));
    } catch (e) {
      Get.snackbar("Error", "Failed to record sale",
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  /// Generate Daily Sales PDF
  Future<void> generateDailySalesPDF(List<Map<String, dynamic>> dailyOrders) async {
    try {
      isLoading.value = true;
      final pdf = pw.Document();

      double grandTotal = dailyOrders.fold<double>(
          0, (sum, order) => sum + ((order['total'] ?? 0) as num).toDouble());

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("Daily Sales Report",
                    style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Text(
                    "Date: ${dailyOrders.isNotEmpty ? DateFormat('dd MMM yyyy').format((dailyOrders[0]['timestamp'] as Timestamp).toDate()) : DateFormat('dd MMM yyyy').format(DateTime.now())}",
                    style: pw.TextStyle(fontSize: 14)),
                pw.SizedBox(height: 16),
                pw.Table.fromTextArray(
                  headers: ["Order ID", "Name", "Phone", "Payment", "Total (BDT)"],
                  data: dailyOrders.map((order) {
                    return [
                      order['orderId'] ?? '',
                      order['name'] ?? '',
                      order['phone'] ?? '',
                      order['paymentMethod'] ?? '',
                      ((order['total'] ?? 0) as num).toStringAsFixed(2),
                    ];
                  }).toList(),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
                  cellStyle: pw.TextStyle(fontSize: 12),
                  headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
                  border: pw.TableBorder.all(width: 0.5),
                  cellAlignment: pw.Alignment.centerLeft,
                  headerAlignment: pw.Alignment.center,
                ),
                pw.SizedBox(height: 16),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Text(
                      "Grand Total: ${grandTotal.toStringAsFixed(2)} BDT",
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue),
                    )
                  ],
                ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
    } catch (e) {
      Get.snackbar("Error", "Failed to generate PDF: $e",
          backgroundColor: Colors.red);
    } finally {
      isLoading.value = false;
    }
  }

  /// Generate Monthly Sales PDF
  Future<void> generateMonthlySalesPDF(List<Map<String, dynamic>> orders, String month) async {
    try {
      isLoading.value = true;
      final pdf = pw.Document();

      // Group orders by day (order timestamp)
      final Map<String, List<Map<String, dynamic>>> ordersByDate = {};
      for (var order in orders) {
        final date = (order['timestamp'] as Timestamp).toDate();
        final dateStr = DateFormat('dd MMM yyyy').format(date);
        ordersByDate.putIfAbsent(dateStr, () => []).add(order);
      }

      // Table data
      final tableData = ordersByDate.entries.map<List<dynamic>>((entry) {
        final date = entry.key;
        final dayOrders = entry.value;
        final totalSales = dayOrders.fold<double>(
            0, (sum, o) => sum + ((o['total'] ?? 0) as num).toDouble());
        return [
          date,
          dayOrders.length.toString(),
          totalSales.toStringAsFixed(2),
        ];
      }).toList();

      // Grand total
      final grandTotal = tableData.fold<double>(
          0, (sum, row) => sum + double.parse(row[2]));

      pdf.addPage(
        pw.Page(
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("Monthly Sales Report",
                    style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Text("Month: $month", style: pw.TextStyle(fontSize: 16)),
                pw.SizedBox(height: 12),
                pw.Text("Grand Total: ${grandTotal.toStringAsFixed(2)} BDT",
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),
                pw.Table.fromTextArray(
                  headers: ['Date', 'Number of Orders', 'Total Sales (BDT)'],
                  data: tableData,
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  cellStyle: pw.TextStyle(fontSize: 12),
                  headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
                  border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2),
                    1: const pw.FlexColumnWidth(1),
                    2: const pw.FlexColumnWidth(1),
                  },
                ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
    } catch (e) {
      Get.snackbar("Error", "Failed to generate PDF: $e",
          backgroundColor: Colors.red);
    } finally {
      isLoading.value = false;
    }
  }
}
