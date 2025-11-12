// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html; // For Flutter Web
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PrintingController extends GetxController {
  Future<void> generateInvoicePDF(
    Map<String, dynamic> order,
    double discountedTotal,
    double discount,
    Map<String, dynamic> customer,
  ) async {
    final pdf = pw.Document();
    final date = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    final List items = order['items'] ?? [];

    // Use a font that supports ৳ symbol (Bengali)
    final font = await PdfGoogleFonts.notoSansBengaliRegular();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        theme: pw.ThemeData.withFont(base: font),
        build: (pw.Context context) => [
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  "Blue Bite Restaurant",
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text("Madaripur Sadar, Beside Lake (Selfie Tower)",
                    style: pw.TextStyle(fontSize: 12)),
                pw.SizedBox(height: 5),
                pw.Text("Invoice", style: pw.TextStyle(fontSize: 16)),
                pw.Divider(thickness: 1),
              ],
            ),
          ),
          pw.SizedBox(height: 10),

          // Customer info
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("Customer Name: ${customer['name'] ?? 'N/A'}"),
                  pw.Text("Mobile: ${customer['mobile'] ?? 'N/A'}"),
                ],
              ),
              pw.Text("Date: $date"),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Divider(),

          // Order details table
          pw.Table.fromTextArray(
            border: pw.TableBorder.all(width: 0.5),
            cellAlignment: pw.Alignment.centerLeft,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            headerHeight: 30,
            cellHeight: 25,
            headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold, color: PdfColors.black),
            cellStyle: const pw.TextStyle(fontSize: 12),
            headers: ["#", "Item", "Qty", "Price", "Total"],
            data: List<List<String>>.generate(
              items.length,
              (index) => [
                (index + 1).toString(),
                items[index]['name'] ?? '',
                "${items[index]['quantity']}",
                "৳${items[index]['price']}",
                "৳${(items[index]['quantity'] ?? 1) * (items[index]['price'] ?? 0)}",
              ],
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Divider(),

          // Total section
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text("Subtotal: ৳${order['total'] ?? 0}",
                    style: const pw.TextStyle(fontSize: 12)),
                pw.Text("Discount: ৳$discount",
                    style: const pw.TextStyle(fontSize: 12)),
                pw.Divider(),
                pw.Text(
                  "Total Payable: ৳${discountedTotal.toStringAsFixed(2)}",
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 30),
          pw.Center(
            child: pw.Text(
              "Thank you for dining with Blue Bite Restaurant!",
              style: pw.TextStyle(
                fontSize: 12,
                color: PdfColors.grey600,
              ),
            ),
          ),
          pw.Center(
            child: pw.Text(
              "We hope to serve you again!",
              style: const pw.TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );

    // Printing or Web preview
    final pdfBytes = await pdf.save();

    if (kIsWeb) {
      // For Web: open PDF in a new tab
      final blob = html.Blob([pdfBytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.window.open(url, '_blank');
    } else {
      // For Mobile/Desktop: use printing plugin
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
      );
    }
  }
}
