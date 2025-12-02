// ignore_for_file: empty_catches

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class BalanceController extends GetxController {
  final RxString selectedMonth = '2025-12'.obs; // default month
  final RxList<String> availableMonths = <String>[].obs;

  final RxDouble totalSales = 0.0.obs;
  final RxDouble totalExpenses = 0.0.obs;
  final RxDouble netProfit = 0.0.obs;
  final RxDouble restaurantSaving = 0.0.obs;
  final RxDouble governingBodyProfit = 0.0.obs;
  final RxList<Map<String, dynamic>> governingBodyShares = <Map<String, dynamic>>[].obs;

  final monthlySalesRef = FirebaseFirestore.instance.collection('monthlySales');
  final monthlyExpensesRef = FirebaseFirestore.instance.collection('monthly_expenses');
  final governingBodyRef = FirebaseFirestore.instance.collection('governingBody');

  @override
  void onInit() {
    super.onInit();
    _fetchAvailableMonths();
    ever(selectedMonth, (_) => loadData());
  }

  // Fetch available months from sales collection
  Future<void> _fetchAvailableMonths() async {
    try {
      final salesSnapshot = await monthlySalesRef.get();
      availableMonths.value = salesSnapshot.docs.map((e) => e.id).toList();
      if (availableMonths.isNotEmpty) selectedMonth.value = availableMonths.last;
    } catch (e) {}
  }

  // Convert "YYYY-MM" → "MMM-YYYY" for expense doc IDs
  String _convertToExpenseDocId(String yyyyMm) {
    final parts = yyyyMm.split('-');
    final monthNum = int.parse(parts[1]);
    final monthName = DateFormat.MMM().format(DateTime(0, monthNum)); // "Dec"
    return '$monthName-${parts[0]}'; // "Dec-2025"
  }

  // Load all data
  Future<void> loadData() async {
    await _fetchMonthlySales();
    await _fetchMonthlyExpenses();
    _calculateNetProfit();
    await _fetchGoverningBodyShares();
  }

  // Fetch total sales for the selected month
  Future<void> _fetchMonthlySales() async {
    try {
      final doc = await monthlySalesRef.doc(selectedMonth.value).get();
      double sum = 0;
      if (doc.exists) {
        final orders = doc.data()?['orders'] as List<dynamic>? ?? [];
        for (var order in orders) {
          sum += (order['total'] as num?)?.toDouble() ?? 0.0;
        }
      }
      totalSales.value = sum;
    } catch (e) {
      totalSales.value = 0.0;
    }
  }

  // Fetch total expenses for the selected month
  Future<void> _fetchMonthlyExpenses() async {
    try {
      final docId = _convertToExpenseDocId(selectedMonth.value);
      final doc = await monthlyExpensesRef.doc(docId).get();
      double sum = 0;
      if (doc.exists) {
        // Use the pre-calculated total if it exists
        sum = (doc.data()?['total'] as num?)?.toDouble() ?? 0.0;

        // If total not stored, sum individual items
        if (sum == 0) {
          final items = doc.data()?['items'] as List<dynamic>? ?? [];
          for (var item in items) {
            sum += (item['total'] as num?)?.toDouble() ?? 0.0;
          }
        }
      }
      totalExpenses.value = sum;
    } catch (e) {
      totalExpenses.value = 0.0;
    }
  }

  // Calculate net profit and restaurant/governing body shares
  void _calculateNetProfit() {
    netProfit.value = totalSales.value - totalExpenses.value;
    restaurantSaving.value = netProfit.value * 0.2;
    governingBodyProfit.value = netProfit.value * 0.8;
  }

  // Fetch governing body shares and calculate their amounts
  Future<void> _fetchGoverningBodyShares() async {
    try {
      final query = await governingBodyRef.get();
      double totalShare = 0;
      List<Map<String, dynamic>> temp = [];
      for (var doc in query.docs) {
        final data = doc.data();
        final share = (data['share'] as num?)?.toDouble() ?? 0.0;
        totalShare += share;
        temp.add({'name': data['name'], 'share': share});
      }
      governingBodyShares.value = temp.map((e) {
        final amount = totalShare == 0 ? 0 : (e['share'] / totalShare) * governingBodyProfit.value;
        return {...e, 'amount': amount};
      }).toList();
    } catch (e) {
      governingBodyShares.clear();
    }
  }
}
