// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../Monthly/controller.dart'; // Import your monthly controller

class DailyExpensesController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final RxList<Map<String, dynamic>> dailyList = <Map<String, dynamic>>[].obs;
  final RxInt dailyTotal = 0.obs;
  final RxBool isLoading = false.obs;
  final Rx<DateTime> selectedDate = DateTime.now().obs;

  String get selectedKey => DateFormat('yyyy-MM-dd').format(selectedDate.value);

  // Monthly controller
  late final MonthlyExpensesController monthlyController;

  @override
  void onInit() {
    super.onInit();
    monthlyController = Get.find<MonthlyExpensesController>();
    _listenToDailyExpenses();
  }

  // Listen for daily expenses of selected date
  void _listenToDailyExpenses() {
    _db
        .collection('daily_expenses')
        .doc(selectedKey)
        .collection('items')
        .orderBy('time', descending: true)
        .snapshots()
        .listen((snapshot) {
      final items = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
          'amount': (data['amount'] as num?)?.toInt() ?? 0,
          'note': data['note'] ?? '',
          'time': data['time'] is Timestamp
              ? (data['time'] as Timestamp).toDate()
              : DateTime.now(),
        };
      }).toList();

      dailyList.assignAll(items);
      dailyTotal.value = items.fold(0, (sum, e) => sum + (e['amount'] as int));
    });
  }

  // Change date and refresh
  void changeDate(DateTime date) {
    selectedDate.value = date;
    _listenToDailyExpenses();
  }

  // Add daily expense & update monthly
  Future<void> addDailyExpense(
    String name,
    int amount, {
    String note = '',
    DateTime? date,
  }) async {
    try {
      isLoading.value = true;
      final expenseDate = date ?? DateTime.now();
      final docKey = DateFormat('yyyy-MM-dd').format(expenseDate);
      final parentDoc = _db.collection('daily_expenses').doc(docKey);

      // Ensure the daily doc exists
      final snapshot = await parentDoc.get();
      if (!snapshot.exists) await parentDoc.set({'createdAt': Timestamp.now()});

      // Add daily expense
      await parentDoc.collection('items').add({
        'name': name,
        'amount': amount,
        'note': note,
        'time': Timestamp.fromDate(expenseDate),
      });

      // Refresh current day's list if needed
      if (selectedKey == docKey) _listenToDailyExpenses();

      // Update monthly expenses automatically
      await monthlyController.addToMonthly(amount: amount, date: expenseDate);
    } finally {
      isLoading.value = false;
    }
  }

  // Delete daily expense & update monthly
  Future<void> deleteDaily(String docId) async {
    try {
      isLoading.value = true;
      final docRef =
          _db.collection('daily_expenses').doc(selectedKey).collection('items').doc(docId);

      final snapshot = await docRef.get();
      if (!snapshot.exists) return;

      final amount = (snapshot['amount'] as num?)?.toInt() ?? 0;
      final time = snapshot['time'] is Timestamp
          ? (snapshot['time'] as Timestamp).toDate()
          : DateTime.now();

      await docRef.delete();

      // Monthly deduction
      await monthlyController.removeFromMonthly(amount: amount, date: time);
    } finally {
      isLoading.value = false;
    }
  }

  // Generate PDF for the selected day
  Future<void> generateDailyPDF() async {
    try {
      isLoading.value = true;
      final pdf = pw.Document();
      final formattedDate = DateFormat('dd MMM yyyy').format(selectedDate.value);

      if (dailyList.isEmpty) {
        pdf.addPage(
          pw.Page(
            build: (context) => pw.Center(
              child: pw.Text('No expenses for $formattedDate',
                  style: pw.TextStyle(fontSize: 18)),
            ),
          ),
        );
      } else {
        pdf.addPage(
          pw.Page(
            build: (context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Daily Expenses - $formattedDate',
                    style: pw.TextStyle(fontSize: 20)),
                pw.SizedBox(height: 20),
                pw.Table.fromTextArray(
                  headers: ['Name', 'Amount', 'Note'],
                  data: dailyList
                      .map((e) => [e['name'], e['amount'].toString(), e['note']])
                      .toList(),
                ),
                pw.SizedBox(height: 20),
                pw.Text('Total: ৳ ${dailyTotal.value}',
                    style: pw.TextStyle(fontSize: 16)),
              ],
            ),
          ),
        );
      }

      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
    } finally {
      isLoading.value = false;
    }
  }
}
