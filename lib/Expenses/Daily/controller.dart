// ignore_for_file: deprecated_member_use, avoid_types_as_parameter_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ExpensesController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Reactive daily list and total
  var dailyList = <Map<String, dynamic>>[].obs;
  var dailyTotal = 0.obs;

  // Today's key
  String get today => DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void onInit() {
    super.onInit();
    _listenToDailyExpenses();
  }

  // ---------------- LISTEN TO DAILY EXPENSES ----------------
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
        };
      }).toList();

      // Update reactive state
      dailyList.value = items;
      dailyTotal.value = items.fold<int>(0, (sum, e) => sum + (e['amount'] as num).toInt());
    });
  }

  // ---------------- ADD DAILY EXPENSE ----------------
Future<void> addDailyExpense(String name, int amount, {String note = ''}) async {
  final parentDoc = _db.collection('daily_expenses').doc(today);

  // Ensure daily doc exists
  final snapshot = await parentDoc.get();
  if (!snapshot.exists) await parentDoc.set({});

  // Add to daily collection
  await parentDoc.collection('items').doc().set({
    'name': name,
    'amount': amount,
    'note': note,
    'time': Timestamp.now(),
  });

  // ---------------- AUTO-SAVE TO MONTHLY ----------------
  final monthKey = DateFormat('MMM-yyyy').format(DateTime.now());
  final monthDocRef = _db.collection('monthly_expenses').doc(monthKey);

  final monthSnapshot = await monthDocRef.get();
  if (!monthSnapshot.exists) {
    // First expense for this month
    await monthDocRef.set({
      'total': amount,
      'items': [
        {'date': today, 'total': amount}
      ],
    });
  } else {
    final data = monthSnapshot.data()!;
    int currentTotal = (data['total'] ?? 0) as int;
    List items = List.from(data['items'] ?? []);

    // Check if today already exists
    int index = items.indexWhere((e) => e['date'] == today);
    if (index >= 0) {
      // Increment today’s total
      items[index]['total'] += amount;
    } else {
      // Add a new day
      items.add({'date': today, 'total': amount});
    }

    await monthDocRef.update({
      'total': currentTotal + amount,
      'items': items,
    });
  }
}


  // ---------------- DELETE DAILY EXPENSE ----------------
  Future<void> deleteDaily(String docId) async {
    final parentDoc = _db.collection('daily_expenses').doc(today);
    await parentDoc.collection('items').doc(docId).delete();
  }

  Future<void> saveDailyToMonthly() async {
    final total = dailyTotal.value;
    if (total == 0) return;

    final monthKey = DateFormat('MMM-yyyy').format(DateTime.now());
    final monthDoc = _db.collection('monthly_expenses').doc(monthKey);

    final snapshot = await monthDoc.get();
    if (!snapshot.exists) {
      await monthDoc.set({
        'total': total,
        'items': [
          {'date': today, 'total': total}
        ],
      });
    } else {
      final data = snapshot.data()!;
      final items = List.from(data['items'] ?? []);
      items.add({'date': today, 'total': total});
      await monthDoc.update({
        'total': (data['total'] ?? 0) + total,
        'items': items,
      });
    }

    // Clear daily items
    final dailyItems = await _db.collection('daily_expenses').doc(today).collection('items').get();
    for (var doc in dailyItems.docs) {
      await doc.reference.delete();
    }

    // Reset reactive state
    dailyList.clear();
    dailyTotal.value = 0;
  }

  // ---------------- GENERATE DAILY PDF ----------------
  Future<void> generateDailyPDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Daily Expenses - $today', style: pw.TextStyle(fontSize: 20)),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headers: ['Name', 'Amount', 'Note'],
              data: dailyList.map((e) => [e['name'], e['amount'].toString(), e['note']]).toList(),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Total: BDT ${dailyTotal.value}', style: pw.TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}
