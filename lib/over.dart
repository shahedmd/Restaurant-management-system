// ignore_for_file: use_build_context_synchronously, deprecated_member_use, empty_catches, curly_braces_in_flow_control_structures

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class TodayOverviewController extends GetxController {
  // Observables
  final RxDouble dailySales = 0.0.obs;
  final RxDouble dailyExpenses = 0.0.obs;
  final RxDouble dailyCash = 0.0.obs;
  final RxInt dailyCustomers = 0.obs;
  final RxInt totalOrdersToday = 0.obs;
  final RxDouble avgOrderValue = 0.0.obs;

  final RxInt customerCancelledOrders = 0.obs;
  final RxInt adminCancelledOrders = 0.obs;

  final RxInt deliveredOrdersToday = 0.obs;
  final RxInt pendingOrdersToday = 0.obs;
  final RxInt processingOrdersToday = 0.obs;

  final RxMap<String, int> bestSellersQty = <String, int>{}.obs;
  final RxMap<String, double> bestSellersRevenue = <String, double>{}.obs;
  final RxList<Map<String, dynamic>> topItemsList = <Map<String, dynamic>>[].obs;

  // Payment totals
  final RxDouble cashTotal = 0.0.obs;
  final RxDouble bkashTotal = 0.0.obs;
  final RxDouble nagadTotal = 0.0.obs;
  final RxDouble bankTotal = 0.0.obs;

  // last delivered orders (for UI)
  final RxList<Map<String, dynamic>> last3DeliveredOrders = <Map<String, dynamic>>[].obs;

  // Firestore refs
  final ordersRef = FirebaseFirestore.instance.collection('orders');
  final cancelledRef = FirebaseFirestore.instance.collection('cancelledOrders');
  final dailyExpensesRef = FirebaseFirestore.instance.collection('daily_expenses');
  final dailySummaryRef = FirebaseFirestore.instance.collection('daily_summary');

  // Subscriptions
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ordersSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _cancelledSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _expensesSub;

  // Helper to build YYYY-MM-DD key
  String _todayKeyLocal(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  void onInit() {
    super.onInit();
    loadHybridOverview();
  }

  @override
  void onClose() {
    _ordersSub?.cancel();
    _cancelledSub?.cancel();
    _expensesSub?.cancel();
    super.onClose();
  }

  Future<void> loadHybridOverview() async {
    final now = DateTime.now();
    final key = _todayKeyLocal(now);

    try {
      final doc = await dailySummaryRef.doc(key).get();
      if (doc.exists && doc.data() != null) {
        _applySummaryDoc(doc.data()!);
        _subscribeToOrdersRange(now, realtime: true);
        _subscribeToCancelledRange(now, realtime: true);
        _subscribeToDailyExpenses(now);
        return;
      }
    } catch (e) {}

    await _subscribeToOrdersRange(now, realtime: true);
    await _subscribeToCancelledRange(now, realtime: true);
    await _subscribeToDailyExpenses(now);
  }

  void _applySummaryDoc(Map<String, dynamic> data) {
    try {
      dailySales.value = double.tryParse(data['dailySales']?.toString() ?? '') ?? 0.0;
      dailyExpenses.value = double.tryParse(data['dailyExpenses']?.toString() ?? '') ?? 0.0;
      dailyCash.value = double.tryParse(data['dailyCash']?.toString() ?? '') ??
          (dailySales.value - dailyExpenses.value);
      dailyCustomers.value = int.tryParse(data['dailyCustomers']?.toString() ?? '') ?? 0;
      totalOrdersToday.value = int.tryParse(data['totalOrders']?.toString() ?? '') ?? 0;
      avgOrderValue.value = double.tryParse(data['avgOrderValue']?.toString() ?? '') ??
          (totalOrdersToday.value > 0 ? dailySales.value / totalOrdersToday.value : 0.0);

      deliveredOrdersToday.value = int.tryParse(data['deliveredOrders']?.toString() ?? '') ?? 0;
      pendingOrdersToday.value = int.tryParse(data['pendingOrders']?.toString() ?? '') ?? 0;
      processingOrdersToday.value = int.tryParse(data['processingOrders']?.toString() ?? '') ?? 0;
      adminCancelledOrders.value = int.tryParse(data['adminCancelled']?.toString() ?? '') ?? 0;
      customerCancelledOrders.value = int.tryParse(data['customerCancelled']?.toString() ?? '') ?? 0;

      cashTotal.value = double.tryParse(data['payments']?['cash']?.toString() ?? '') ?? 0.0;
      bkashTotal.value = double.tryParse(data['payments']?['bkash']?.toString() ?? '') ?? 0.0;
      nagadTotal.value = double.tryParse(data['payments']?['nagad']?.toString() ?? '') ?? 0.0;
      bankTotal.value = double.tryParse(data['payments']?['bank']?.toString() ?? '') ?? 0.0;

      final items = (data['topItems'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      topItemsList.value = items.map((m) => Map<String, dynamic>.from(m)).toList();

      final last = (data['lastDelivered'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      last3DeliveredOrders.value = last.map((m) => Map<String, dynamic>.from(m)).toList();
    } catch (e) {}
  }

  // ========================= ORDERS =========================
  Future<void> _subscribeToOrdersRange(DateTime now, {bool realtime = false}) async {
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    await _ordersSub?.cancel();

    final query = ordersRef
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .where('timestamp', isLessThan: Timestamp.fromDate(todayEnd));

    if (realtime) {
      _ordersSub = query.snapshots().listen(
        (snap) => _computeFromOrdersSnapshot(snap.docs.map((d) => d.data()).toList()),
        onError: (e) {},
      );
    } else {
      final snap = await query.get();
      _computeFromOrdersSnapshot(snap.docs.map((d) => d.data()).toList());
    }
  }

  void _computeFromOrdersSnapshot(List<Map<String, dynamic>> docs) {
    double sales = 0.0;
    final Set<String> customers = {};
    int deliveredCount = 0, pendingCount = 0, processingCount = 0, adminCancelled = 0;
    int totalOrders = docs.length;

    double cashSum = 0.0, bkashSum = 0.0, nagadSum = 0.0, bankSum = 0.0;
    bestSellersQty.clear();
    bestSellersRevenue.clear();
    topItemsList.clear();
    final List<Map<String, dynamic>> deliveredOrders = [];

    for (final data in docs) {
      final status = (data['status'] ?? '').toString().toLowerCase();
      final total = double.tryParse(data['total']?.toString() ?? '') ?? 0.0;

      DateTime? ts;
      try {
        final rawTs = data['timestamp'];
        if (rawTs is Timestamp) ts = rawTs.toDate();
        else if (rawTs is DateTime) ts = rawTs;
      } catch (_) { ts = null; }

      if (status == 'delivered') {
        deliveredCount++;
        sales += total;
        deliveredOrders.add({
          'tableNo': data['tableNo'] ?? 'N/A',
          'total': total,
          'orderType': data['orderType'] ?? 'N/A',
          'timestamp': ts,
        });

        final pm = (data['paymentMethod'] ?? '').toString().toLowerCase();
        switch (pm) {
          case 'cash': cashSum += total; break;
          case 'bkash': bkashSum += total; break;
          case 'nagad': nagadSum += total; break;
          case 'bank': bankSum += total; break;
        }
      } else if (status == 'pending') pendingCount++;
      else if (status == 'processing') processingCount++;
      else if (status == 'cancelled') adminCancelled++;

      final phone = (data['phone'] ?? '').toString();
      if (phone.isNotEmpty) customers.add(phone);

      final items = (data['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      for (var raw in items) {
        final name = raw['name']?.toString() ?? '';
        final qty = int.tryParse(raw['quantity']?.toString() ?? '') ?? 0;
        final price = double.tryParse(raw['price']?.toString() ?? '') ?? 0.0;
        if (name.isEmpty) continue;
        bestSellersQty[name] = (bestSellersQty[name] ?? 0) + qty;
        bestSellersRevenue[name] = (bestSellersRevenue[name] ?? 0.0) + (price * qty);
      }
    }

    final itemsList = bestSellersQty.entries.map((e) {
      final rev = bestSellersRevenue[e.key] ?? 0.0;
      return {'name': e.key, 'qty': e.value, 'revenue': rev};
    }).toList();
    itemsList.sort((a, b) {
      final qa = a['qty'] as int;
      final qb = b['qty'] as int;
      if (qb != qa) return qb.compareTo(qa);
      return (b['revenue'] as double).compareTo(a['revenue'] as double);
    });

    deliveredOrders.sort((a, b) {
      final da = a['timestamp'] as DateTime?;
      final db = b['timestamp'] as DateTime?;
      if (da == null || db == null) return 0;
      return db.compareTo(da);
    });

    dailySales.value = sales;
    deliveredOrdersToday.value = deliveredCount;
    pendingOrdersToday.value = pendingCount;
    processingOrdersToday.value = processingCount;
    adminCancelledOrders.value = adminCancelled;
    totalOrdersToday.value = totalOrders;
    dailyCustomers.value = customers.length;
    avgOrderValue.value = totalOrders > 0 ? (sales / totalOrders) : 0.0;

    cashTotal.value = cashSum;
    bkashTotal.value = bkashSum;
    nagadTotal.value = nagadSum;
    bankTotal.value = bankSum;

    topItemsList.value = itemsList;
    last3DeliveredOrders.value = deliveredOrders.take(3).toList();
    dailyCash.value = sales - dailyExpenses.value;
  }

  Future<void> _subscribeToCancelledRange(DateTime now, {bool realtime = false}) async {
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    await _cancelledSub?.cancel();

    final q = cancelledRef
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .where('timestamp', isLessThan: Timestamp.fromDate(todayEnd));

    if (realtime) {
      _cancelledSub = q.snapshots().listen((snap) {
        var cc = 0;
        for (var d in snap.docs) {
          final data = d.data();
          if ((data['cancelledByUser'] ?? true) == true) cc++;
        }
        customerCancelledOrders.value = cc;
      });
    } else {
      final snap = await q.get();
      var cc = 0;
      for (var d in snap.docs) {
        final data = d.data();
        if ((data['cancelledByUser'] ?? true) == true) cc++;
      }
      customerCancelledOrders.value = cc;
    }
  }

  Future<void> _subscribeToDailyExpenses(DateTime now) async {
    final key = _todayKeyLocal(now);
    await _expensesSub?.cancel();

    _expensesSub = dailyExpensesRef.doc(key).collection('items').snapshots().listen((snap) {
      double expensesSum = 0.0;
      for (var doc in snap.docs) {
        expensesSum += double.tryParse(doc.data()['amount']?.toString() ?? '') ?? 0.0;
      }
      dailyExpenses.value = expensesSum;
      dailyCash.value = dailySales.value - expensesSum;
    });
  }
}

// ========================= PAGE =========================

class TodayOverviewPage extends StatefulWidget {
  const TodayOverviewPage({super.key});
  @override
  State<TodayOverviewPage> createState() => _TodayOverviewPageState();
}

class _TodayOverviewPageState extends State<TodayOverviewPage> with SingleTickerProviderStateMixin {
  final TodayOverviewController ctrl = Get.put(TodayOverviewController());
  final NumberFormat currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: 'BDT');

  late final AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool wide = width > 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Today's Overview", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 2, 41, 87),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Obx(() => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _heroGrid(wide),
            SizedBox(height: 14.h),
            _statusGrid(wide),
            SizedBox(height: 18.h),
            wide ? Row(children: [Expanded(child: _paymentCard()), SizedBox(width: 12.w), Expanded(child: _topItemsCard())]) :
                Column(children: [_paymentCard(), SizedBox(height: 12.h), _topItemsCard()]),
            SizedBox(height: 18.h),
            _recentDeliveredCard(),
            SizedBox(height: 30.h),
          ],
        )),
      ),
    );
  }

  Widget _heroGrid(bool wide) => AnimatedOpacity(
    opacity: 1.0,
    duration: const Duration(milliseconds: 500),
    child: GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: wide ? 4 : 2,
      shrinkWrap: true,
      crossAxisSpacing: 12.w,
      mainAxisSpacing: 12.h,
      childAspectRatio: 1.6,
      children: [
        _heroCard('Total Sales', 'Today', currencyFormat.format(ctrl.dailySales.value), FontAwesomeIcons.moneyBillWave, Colors.blue),
        _heroCard('Expenses', 'Today', currencyFormat.format(ctrl.dailyExpenses.value), FontAwesomeIcons.moneyCheckDollar, Colors.red),
        _heroCard('Net Cash', 'Today', currencyFormat.format(ctrl.dailyCash.value), FontAwesomeIcons.cashRegister, Colors.green),
        _heroCard('Total Orders', 'Today', ctrl.totalOrdersToday.value.toString(), FontAwesomeIcons.clipboardList, Colors.purple),
      ],
    ),
  );

  Widget _statusGrid(bool wide) => GridView.count(
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: wide ? 4 : 2,
    shrinkWrap: true,
    crossAxisSpacing: 12.w,
    mainAxisSpacing: 12.h,
    childAspectRatio: 2.6,
    children: [
      _statusPill('Delivered', ctrl.deliveredOrdersToday.value, Colors.teal),
      _statusPill('Processing', ctrl.processingOrdersToday.value, Colors.blue),
      _statusPill('Pending', ctrl.pendingOrdersToday.value, Colors.deepPurple),
      _statusPill('Avg Order', null, Colors.indigo, textRight: currencyFormat.format(ctrl.avgOrderValue.value)),
    ],
  );

  Widget _heroCard(String title, String subtitle, String amount, IconData icon, Color color) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12.r)),
        child: Row(children: [
          FaIcon(icon, color: color, size: 32.sp),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500)),
              Text(subtitle, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w400)),
              SizedBox(height: 6.h),
              Text(amount, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
            ],
          )
        ]),
      ),
    );
  }

  Widget _statusPill(String label, int? value, Color color, {String? textRight}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12.r)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500)),
        Text(textRight ?? (value?.toString() ?? '0'), style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _paymentCard() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12.r)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Payment Breakdown', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
        SizedBox(height: 12.h),
        _paymentRow('Cash', ctrl.cashTotal.value),
        _paymentRow('Bkash', ctrl.bkashTotal.value),
        _paymentRow('Nagad', ctrl.nagadTotal.value),
        _paymentRow('Bank', ctrl.bankTotal.value),
      ]),
    );
  }

  Widget _paymentRow(String label, double amount) => Padding(
    padding: EdgeInsets.symmetric(vertical: 4.h),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontSize: 14.sp)),
      Text(currencyFormat.format(amount), style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
    ]),
  );

  Widget _topItemsCard() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12.r)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Top Items', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
        SizedBox(height: 12.h),
        ...ctrl.topItemsList.take(5).map((item) => Padding(
          padding: EdgeInsets.symmetric(vertical: 4.h),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(item['name'] ?? '', style: TextStyle(fontSize: 14.sp)),
            Text('${item['qty'] ?? 0} pcs', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
          ]),
        )),
      ]),
    );
  }

  Widget _recentDeliveredCard() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(12.r)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Last Delivered Orders', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
        SizedBox(height: 12.h),
        ...ctrl.last3DeliveredOrders.map((order) => Padding(
          padding: EdgeInsets.symmetric(vertical: 4.h),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Table ${order['tableNo'] ?? 'N/A'}', style: TextStyle(fontSize: 14.sp)),
            Text(currencyFormat.format(order['total'] ?? 0.0), style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
          ]),
        )),
      ]),
    );
  }
}
