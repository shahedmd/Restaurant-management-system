// ignore_for_file: deprecated_member_use, avoid_types_as_parameter_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class MonthlyExpensesController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  var monthlyList = <Map<String, dynamic>>[].obs;
  var monthlyTotal = 0.obs;
  var isLoading = false.obs; // Loading indicator

  @override
  void onInit() {
    super.onInit();
    fetchMonthlyExpenses();
  }

  // Fetch all monthly expenses
  void fetchMonthlyExpenses() {
    _db
        .collection('monthly_expenses')
        .orderBy('total', descending: true)
        .snapshots()
        .listen((snapshot) {
      final months = snapshot.docs.map((doc) {
        final items = List<Map<String, dynamic>>.from(doc['items'] ?? []);
        return {
          'month': doc.id, // e.g., Nov-2025
          'total': doc['total'] ?? 0,
          'items': items,
        };
      }).toList();

      monthlyList.value = months;
      monthlyTotal.value =
          months.fold<int>(0, (sum, m) => sum + (m['total'] as int));
    });
  }

  // Generate PDF for a specific month
  Future<void> generateMonthlyPDF(String month) async {
    try {
      isLoading.value = true; // Start loading

      final monthData = monthlyList.firstWhere(
        (m) => m['month'] == month,
        orElse: () => {'month': month, 'total': 0, 'items': []},
      );

      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Monthly Expenses - $month',
                  style: pw.TextStyle(fontSize: 20)),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['Date', 'Total'],
                data: (monthData['items'] as List)
                    .map((e) => [e['date'], e['total'].toString()])
                    .toList(),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Total: BDT ${monthData['total']}',
                  style: pw.TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );

      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
    } finally {
      isLoading.value = false; // Stop loading
    }
  }
}
