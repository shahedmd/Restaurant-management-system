// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
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
    Map<String, dynamic> pointsInfo,
  ) async {
    final pdf = pw.Document();
    final date = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    final items = (order['items'] ?? []) as List<dynamic>;

    // Fonts (preload once)
    final font = await PdfGoogleFonts.notoSansBengaliRegular();
    final boldFont = await PdfGoogleFonts.notoSansBengaliBold();

    final paymentMethod = order['paymentMethod']?.toString() ?? 'N/A';
    final transactionId = order['transactionId']?.toString() ?? 'N/A';

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(
          80 * PdfPageFormat.mm,
          double.infinity,
          marginAll: 5 * PdfPageFormat.mm,
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ===== HEADER =====
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text("Bluebite", style: pw.TextStyle(fontSize: 16, font: boldFont)),
                    pw.Text(
                      "Watch Tower(Selfie tower) west side, Circuir house road, Lake side, New Town, Madaripur",
                      style: pw.TextStyle(fontSize: 7, font: font),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.Text("Hotline: 01727530313", style: pw.TextStyle(fontSize: 9, font: font)),
                    pw.SizedBox(height: 5),
                    pw.Text("Invoice", style: pw.TextStyle(fontSize: 12, font: boldFont)),
                    pw.Divider(thickness: 0.8),
                  ],
                ),
              ),
              pw.SizedBox(height: 3),

              // ===== CUSTOMER INFO =====
              pw.Text("Customer: ${customer['name']}", style: pw.TextStyle(font: font, fontSize: 9)),
              pw.Text("Mobile: ${customer['mobile']}", style: pw.TextStyle(font: font, fontSize: 9)),
              pw.Text("Date: $date", style: pw.TextStyle(font: font, fontSize: 9)),
              pw.Text("Payment Method: $paymentMethod", style: pw.TextStyle(font: font, fontSize: 9)),
              pw.Text("Transaction ID: $transactionId", style: pw.TextStyle(font: font, fontSize: 9)),
              pw.Divider(thickness: 0.8),

              // ===== ITEMS HEADER =====
              pw.Row(
                children: [
                  pw.Expanded(flex: 4, child: pw.Text("Item", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 1, child: pw.Text("Qty", textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 2, child: pw.Text("Price", textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 2, child: pw.Text("Total", textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                ],
              ),
              pw.Divider(thickness: 0.5),

              // ===== ITEMS LIST =====
              ...items.map<pw.Widget>((item) {
                final name = item['name']?.toString() ?? '';
                final qty = (item['quantity'] ?? 1) as int;
                double price = 0;

                if (item['selectedVariant'] != null && item['selectedVariant'] is Map && item['selectedVariant']['price'] != null) {
                  price = (item['selectedVariant']['price'] as num).toDouble();
                } else if (item['price'] != null) {
                  price = (item['price'] as num).toDouble();
                }

                final total = qty * price;

                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 1),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 4,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(name, style: pw.TextStyle(fontSize: 9, font: font)),
                            if (item['selectedVariant'] != null && item['selectedVariant']['size'] != null)
                              pw.Text("(${item['selectedVariant']['size']})", style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                          ],
                        ),
                      ),
                      pw.Expanded(flex: 1, child: pw.Text("$qty", textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 9))),
                      pw.Expanded(flex: 2, child: pw.Text("BDT${price.toStringAsFixed(0)}", textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 9))),
                      pw.Expanded(flex: 2, child: pw.Text("BDT${total.toStringAsFixed(0)}", textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 9))),
                    ],
                  ),
                );
              }),

              pw.Divider(thickness: 0.8),
              pw.SizedBox(height: 5),

              // ===== TOTALS =====
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text("Subtotal:", style: pw.TextStyle(fontSize: 10, font: font)),
                pw.Text("BDT${(order['total'] ?? 0).toStringAsFixed(2)}", style: pw.TextStyle(fontSize: 10, font: font)),
              ]),

              // ===== DISCOUNT =====
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text("Manual Discount:", style: pw.TextStyle(fontSize: 10, font: font)),
                pw.Text("-BDT${(discount - (pointsInfo['pointsUsed'] ?? 0)).toStringAsFixed(2)}", style: pw.TextStyle(fontSize: 10, font: font)),
              ]),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text("Points Used:", style: pw.TextStyle(fontSize: 10, font: font)),
                pw.Text("-BDT${(pointsInfo['pointsUsed'] ?? 0)}", style: pw.TextStyle(fontSize: 10, font: font)),
              ]),

              pw.Divider(thickness: 0.5),

              // ===== FINAL TOTAL =====
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text("Total Payable:", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.Text("BDT${discountedTotal.toStringAsFixed(2)}", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              ]),

              pw.SizedBox(height: 8),

              // ===== POINTS INFO =====
              pw.Text("---- Loyalty Points ----", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.Text("Previous Points: ${pointsInfo['originalPoints']}", style: pw.TextStyle(fontSize: 9, font: font)),
              pw.Text("Used: ${pointsInfo['pointsUsed']}", style: pw.TextStyle(fontSize: 9, font: font)),
              pw.Text("Earned: ${pointsInfo['pointsEarned']}", style: pw.TextStyle(fontSize: 9, font: font)),
              pw.Text("Remaining: ${pointsInfo['pointsRemaining']}", style: pw.TextStyle(fontSize: 9, font: font)),

              pw.SizedBox(height: 10),

              // ===== FOOTER =====
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text("Thank you!", style: pw.TextStyle(fontSize: 9)),
                    pw.Text("Please visit us again.", style: pw.TextStyle(fontSize: 9)),
                    pw.SizedBox(height: 5),
                    pw.Text("Powered by Blue Bite RMS", style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
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
      await Printing.layoutPdf(onLayout: (format) async => pdfBytes, name: "BlueBite_Invoice");
    }
  }
}
