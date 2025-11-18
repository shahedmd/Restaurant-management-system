// ignore_for_file: deprecated_member_use, avoid_types_as_parameter_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';


class ExpensesController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  var dailyList = <Map<String, dynamic>>[].obs;
  var dailyTotal = 0.obs;
  var isLoading = false.obs; // Loading indicator

  String get today => DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void onInit() {
    super.onInit();
    _listenToDailyExpenses();
  }

  void _listenToDailyExpenses() {
    _db
        .collection('daily_expenses')
        .doc(today)
        .collection('items')
        .orderBy('time', descending: true)
        .snapshots()
        .listen((snapshot) {
      final items = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'name': doc['name'],
          'amount': doc['amount'],
          'note': doc['note'],
          'time': doc['time'] is Timestamp ? (doc['time'] as Timestamp).toDate() : doc['time'],
        };
      }).toList();

      dailyList.value = items;
      dailyTotal.value = items.fold<int>(
          0, (sum, e) => sum + (e['amount'] as num).toInt());
    });
  }

Future<void> addDailyExpense(
  String name,
  int amount, {
  String note = '',
  DateTime? date,
}) async {
  isLoading.value = true;

  final expenseDate = date ?? DateTime.now();
  final todayKey = DateFormat('yyyy-MM-dd').format(expenseDate);
  final parentDoc = _db.collection('daily_expenses').doc(todayKey);

  // Ensure daily doc exists
  final snapshot = await parentDoc.get();
  if (!snapshot.exists) {
    await parentDoc.set({'createdAt': Timestamp.now()});
  }

  // Add to Firestore daily collection
  await parentDoc.collection('items').add({
    'name': name,
    'amount': amount,
    'note': note,
    'time': Timestamp.fromDate(expenseDate),
  });

  // Auto-save to monthly
  final monthKey = DateFormat('MMM-yyyy').format(expenseDate);
  final monthDocRef = _db.collection('monthly_expenses').doc(monthKey);
  final monthSnapshot = await monthDocRef.get();

  if (!monthSnapshot.exists) {
    await monthDocRef.set({
      'total': amount,
      'items': [
        {'date': todayKey, 'total': amount}
      ],
      'createdAt': Timestamp.now(),
    });
  } else {
    final data = monthSnapshot.data()!;
    int currentTotal = (data['total'] ?? 0) as int;
    List items = List.from(data['items'] ?? []);
    int index = items.indexWhere((e) => e['date'] == todayKey);

    if (index >= 0) {
      items[index]['total'] += amount;
    } else {
      items.add({'date': todayKey, 'total': amount});
    }

    await monthDocRef.update({
      'total': currentTotal + amount,
      'items': items,
    });
  }

isLoading.value = false;
}


 Future<void> deleteDaily(String docId) async {
  try {
    isLoading.value = true;

    final parentDoc = _db.collection('daily_expenses').doc(today);
    final docRef = parentDoc.collection('items').doc(docId);

    // Get the document to know the amount
    final snapshot = await docRef.get();
    if (!snapshot.exists) return;

    final amount = (snapshot['amount'] as num).toInt();
    final time = snapshot['time'] is Timestamp
        ? (snapshot['time'] as Timestamp).toDate()
        : snapshot['time'];

    // Delete from daily
    await docRef.delete();

    // Update monthly expenses
    final monthKey = DateFormat('MMM-yyyy').format(time);
    final monthDocRef = _db.collection('monthly_expenses').doc(monthKey);
    final monthSnapshot = await monthDocRef.get();

    if (monthSnapshot.exists) {
      final data = monthSnapshot.data()!;
      int currentTotal = (data['total'] ?? 0) as int;
      List items = List.from(data['items'] ?? []);

      // Find the day entry
      int index = items.indexWhere((e) => e['date'] == DateFormat('yyyy-MM-dd').format(time));
      if (index >= 0) {
        items[index]['total'] -= amount;

        // Remove day if total becomes 0
        if (items[index]['total'] <= 0) {
          items.removeAt(index);
        }
      }

      // Update monthly total
      await monthDocRef.update({
        'total': currentTotal - amount,
        'items': items,
      });
    }
  } finally {
    isLoading.value = false;
  }
}



  Future<void> generateDailyPDF() async {
    try {
      isLoading.value = true;
      final pdf = pw.Document();
      final formattedDate = DateFormat('dd MMM yyyy').format(DateTime.now());

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Daily Expenses - $formattedDate', style: pw.TextStyle(fontSize: 20)),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['Name', 'Amount', 'Note'],
                data: dailyList
                    .map((e) => [e['name'], e['amount'].toString(), e['note'] ?? ''])
                    .toList(),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Total: BDT ${dailyTotal.value}', style: pw.TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );

      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
    } finally {
      isLoading.value = false;
    }
  }
}
