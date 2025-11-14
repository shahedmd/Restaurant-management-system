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
    final items = order['items'] ?? [];

    // Use a clear, simple font
    final font = await PdfGoogleFonts.notoSansBengaliRegular();
    final boldFont = await PdfGoogleFonts.notoSansBengaliBold();

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(80 * PdfPageFormat.mm, double.infinity,
            marginAll: 5 * PdfPageFormat.mm), // ✅ 80mm paper width
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ===== HEADER =====
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      "Blue Bite Restaurant",
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        font: boldFont,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.Text(
                      "Madaripur Sadar, Beside Lake (Selfie Tower)",
                      style: pw.TextStyle(fontSize: 9, font: font),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text("☎ 017XXXXXXXX", style: pw.TextStyle(fontSize: 9, font: font)),
                    pw.SizedBox(height: 5),
                    pw.Text("Invoice", style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                    pw.Divider(thickness: 0.8),
                  ],
                ),
              ),
              pw.SizedBox(height: 3),

              // ===== CUSTOMER INFO =====
              pw.Text("Customer: ${customer['name'] ?? 'N/A'}", style: pw.TextStyle(font: font, fontSize: 9)),
              pw.Text("Mobile: ${customer['mobile'] ?? 'N/A'}", style: pw.TextStyle(font: font, fontSize: 9)),
              pw.Text("Date: $date", style: pw.TextStyle(font: font, fontSize: 9)),
              pw.Divider(thickness: 0.8),

              // ===== ITEMS HEADER =====
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                      flex: 4,
                      child: pw.Text("Item", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                  pw.Expanded(
                      flex: 1,
                      child: pw.Text("Qty", textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                  pw.Expanded(
                      flex: 2,
                      child: pw.Text("Price", textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                  pw.Expanded(
                      flex: 2,
                      child: pw.Text("Total", textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9))),
                ],
              ),
              pw.Divider(thickness: 0.6),

              // ===== ITEMS LIST =====
              ...items.map<pw.Widget>((item) {
                final name = item['name'] ?? '';
                final qty = item['quantity'] ?? 1;
                final price = (item['price'] ?? 0).toDouble();
                final total = qty * price;

                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 1),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(flex: 4, child: pw.Text(name, style: pw.TextStyle(fontSize: 9))),
                      pw.Expanded(flex: 1, child: pw.Text("$qty", textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 9))),
                      pw.Expanded(
                          flex: 2,
                          child: pw.Text("BDT${price.toStringAsFixed(0)}",
                              textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 9))),
                      pw.Expanded(
                          flex: 2,
                          child: pw.Text("BDT${total.toStringAsFixed(0)}",
                              textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 9))),
                    ],
                  ),
                );
              }).toList(),

              pw.Divider(thickness: 0.8),

              // ===== TOTAL SECTION =====
              pw.SizedBox(height: 5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Subtotal:", style: pw.TextStyle(font: font, fontSize: 10)),
                  pw.Text("BDT${(order['total'] ?? 0).toStringAsFixed(2)}",
                      style: pw.TextStyle(font: font, fontSize: 10)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Discount:", style: pw.TextStyle(font: font, fontSize: 10)),
                  pw.Text("-BDT${discount.toStringAsFixed(2)}",
                      style: pw.TextStyle(font: font, fontSize: 10)),
                ],
              ),
              pw.Divider(thickness: 0.5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Total Payable:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                  pw.Text("BDT${discountedTotal.toStringAsFixed(2)}",
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                ],
              ),
              pw.SizedBox(height: 10),

              // ===== FOOTER =====
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Divider(thickness: 0.5),
                    pw.Text("Thank you for dining with us!",
                        style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                    pw.Text("We hope to serve you again soon!",
                        style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                    pw.SizedBox(height: 5),
                    pw.Text("Powered by Blue Bite RMS",
                        style: pw.TextStyle(fontSize: 8, color: PdfColors.grey400)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    final pdfBytes = await pdf.save();

    if (kIsWeb) {
      final blob = html.Blob([pdfBytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.window.open(url, '_blank');
    } else {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: "BlueBite_Invoice",
      );
    }
  }
}
