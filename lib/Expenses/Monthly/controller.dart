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

  // Fetch all monthly expenses reactively
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

      monthlyList.assignAll(months);
      monthlyTotal.value =
          months.fold<int>(0, (sum, m) => sum + (m['total'] as int));
    });
  }

  // Add daily amount to monthly collection
  Future<void> addToMonthly({required int amount, required DateTime date}) async {
    final monthKey = "${_monthString(date.month)}-${date.year}";
    final dayKey = "${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}";
    final docRef = _db.collection('monthly_expenses').doc(monthKey);
    final snapshot = await docRef.get();

    if (!snapshot.exists) {
      await docRef.set({
        'total': amount,
        'items': [
          {'date': dayKey, 'total': amount}
        ],
        'createdAt': Timestamp.now(),
      });
    } else {
      final data = snapshot.data()!;
      int currentTotal = (data['total'] ?? 0) as int;
      List items = List.from(data['items'] ?? []);
      int index = items.indexWhere((e) => e['date'] == dayKey);

      if (index >= 0) {
        items[index]['total'] += amount;
      } else {
        items.add({'date': dayKey, 'total': amount});
      }

      await docRef.update({
        'total': currentTotal + amount,
        'items': items,
      });
    }
  }

  // Remove amount from monthly collection (used when deleting daily expense)
  Future<void> removeFromMonthly({required int amount, required DateTime date}) async {
    final monthKey = "${_monthString(date.month)}-${date.year}";
    final dayKey = "${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}";
    final docRef = _db.collection('monthly_expenses').doc(monthKey);
    final snapshot = await docRef.get();
    if (!snapshot.exists) return;

    final data = snapshot.data()!;
    int currentTotal = (data['total'] ?? 0) as int;
    List items = List.from(data['items'] ?? []);
    int index = items.indexWhere((e) => e['date'] == dayKey);

    if (index >= 0) {
      items[index]['total'] -= amount;
      if (items[index]['total'] <= 0) {
        items.removeAt(index);
      }
    }

    await docRef.update({
      'total': currentTotal - amount,
      'items': items,
    });
  }

  // Helper: month number to string
  String _monthString(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
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
