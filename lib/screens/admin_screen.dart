import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../main.dart';
import '../models.dart';
import '../services/storage_service.dart';
import '../services/pdf_service.dart';
import 'login_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Allotment> _allotments = [];
  List<Expense> _expenses = [];
  bool _loading = true;
  StreamSubscription? _allotmentsSub;
  StreamSubscription? _expensesSub;

  // Allot form
  String _allotTable = 'Reception 1';
  final _allotAmountCtrl = TextEditingController();

  // Download form
  late DateTime _dlFrom;
  late DateTime _dlTo;
  String _dlTable = 'all';
  bool _generating = false;

  final _currFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  final _dateFmt = DateFormat('dd MMM yyyy');
  final _timeFmt = DateFormat('hh:mm a');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final now = DateTime.now();
    _dlFrom = DateTime(now.year, now.month, 1);
    _dlTo = now;
    _loadData();
  }

  void _loadData() {
    _allotmentsSub = StorageService.streamAllotments().listen((data) {
      setState(() {
        _allotments = data;
        _loading = false;
      });
    });
    _expensesSub = StorageService.streamExpenses().listen((data) {
      setState(() {
        _expenses = data;
        _loading = false;
      });
    });
  }

  double _getBalance(String table) {
    final allotted =
        _allotments.where((a) => a.table == table).fold(0.0, (s, a) => s + a.amount);
    final spent =
        _expenses.where((e) => e.table == table).fold(0.0, (s, e) => s + e.amount);
    return allotted - spent;
  }

  double _getTotalAllotted(String table) =>
      _allotments.where((a) => a.table == table).fold(0.0, (s, a) => s + a.amount);

  double _getTotalSpent(String table) =>
      _expenses.where((e) => e.table == table).fold(0.0, (s, e) => s + e.amount);

  void _handleAllot() {
    final amt = double.tryParse(_allotAmountCtrl.text);
    if (amt == null || amt <= 0) {
      _showSnack('Enter a valid amount', isError: true);
      return;
    }

    final allotment = Allotment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      table: _allotTable,
      amount: amt,
    );

    StorageService.addAllotment(allotment);
    _allotAmountCtrl.clear();
    _showSnack('${_currFmt.format(amt)} allotted to $_allotTable');
  }

  Future<void> _handleDownload() async {
    setState(() => _generating = true);
    try {
      await PdfService.generate(
        allotments: _allotments,
        expenses: _expenses,
        from: _dlFrom,
        to: _dlTo,
        selectedTable: _dlTable,
      );
    } catch (e) {
      _showSnack('Error generating PDF: $e', isError: true);
    }
    setState(() => _generating = false);
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.red : AppColors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  void dispose() {
    _allotmentsSub?.cancel();
    _expensesSub?.cancel();
    _tabController.dispose();
    _allotAmountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator(color: AppColors.navy)));
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.account_balance_wallet_rounded, size: 22),
            const SizedBox(width: 10),
            const Text('Petty Cash'),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('Admin',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 20),
            onPressed: () => Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const LoginScreen())),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabs: const [
            Tab(text: 'Activity'),
            Tab(text: 'Allot Cash'),
            Tab(text: 'Download'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Balance cards
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                _balanceCard('Reception 1', const Color(0xFF1A3A5C)),
                const SizedBox(width: 12),
                _balanceCard('Reception 2', const Color(0xFF2C3E50)),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _activityTab(),
                _allotTab(),
                _downloadTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _balanceCard(String table, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.85)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(table,
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(_currFmt.format(_getBalance(table)),
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
            const SizedBox(height: 6),
            Text(
              'In: ${_currFmt.format(_getTotalAllotted(table))}  ·  Out: ${_currFmt.format(_getTotalSpent(table))}',
              style: TextStyle(
                  fontSize: 10, color: Colors.white.withValues(alpha: 0.65)),
            ),
          ],
        ),
      ),
    );
  }

  // ─── ACTIVITY TAB ───
  Widget _activityTab() {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayExps = _expenses
        .where((e) => DateFormat('yyyy-MM-dd').format(e.date) == todayStr)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final recentAllots = _allotments.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle(Icons.receipt_long_rounded, "Today's Expenses"),
        Card(
          child: todayExps.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                      child: Text('No expenses today',
                          style: TextStyle(color: AppColors.grey))))
              : Column(
                  children: todayExps
                      .map((e) => _expenseItem(e, showTable: true))
                      .toList(),
                ),
        ),
        const SizedBox(height: 8),
        _sectionTitle(Icons.wallet_rounded, 'Recent Allotments'),
        Card(
          child: recentAllots.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                      child: Text('No allotments yet',
                          style: TextStyle(color: AppColors.grey))))
              : Column(
                  children: recentAllots
                      .take(10)
                      .map((a) => ListTile(
                            dense: true,
                            title: Text(a.table,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: Text(_dateFmt.format(a.date),
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.grey)),
                            trailing: Text('+${_currFmt.format(a.amount)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.green,
                                    fontSize: 15)),
                          ))
                      .toList(),
                ),
        ),
      ],
    );
  }

  // ─── ALLOT TAB ───
  Widget _allotTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle(Icons.add_circle_outline_rounded, 'Allot Petty Cash'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('RECEPTION TABLE'),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.inputBg,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: AppColors.inputBorder, width: 2),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _allotTable,
                      isExpanded: true,
                      icon: const Icon(Icons.expand_more_rounded),
                      items: ['Reception 1', 'Reception 2']
                          .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(t,
                                  style: const TextStyle(fontSize: 14))))
                          .toList(),
                      onChanged: (v) => setState(() => _allotTable = v!),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _label('AMOUNT (₹)'),
                const SizedBox(height: 8),
                TextField(
                  controller: _allotAmountCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  decoration: const InputDecoration(
                    hintText: 'e.g. 2000',
                    prefixText: '₹ ',
                  ),
                  onSubmitted: (_) => _handleAllot(),
                ),
                const SizedBox(height: 16),

                // Quick amounts
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [500, 1000, 2000, 5000].map((q) {
                    final isSelected = _allotAmountCtrl.text == q.toString();
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _allotAmountCtrl.text = q.toString()),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color:
                              isSelected ? AppColors.navy : AppColors.inputBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.navy
                                : AppColors.inputBorder,
                            width: 2,
                          ),
                        ),
                        child: Text('₹${NumberFormat('#,##0').format(q)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.navy,
                            )),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _handleAllot,
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text('Allot Cash'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── DOWNLOAD TAB ───
  Widget _downloadTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle(Icons.download_rounded, 'Download Statement'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick selectors
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _periodChip('This Week', () {
                      final now = DateTime.now();
                      final weekday = now.weekday;
                      setState(() {
                        _dlFrom = now.subtract(Duration(days: weekday - 1));
                        _dlTo = now;
                      });
                    }),
                    _periodChip('This Month', () {
                      final now = DateTime.now();
                      setState(() {
                        _dlFrom = DateTime(now.year, now.month, 1);
                        _dlTo = now;
                      });
                    }),
                    _periodChip('Last Month', () {
                      final now = DateTime.now();
                      setState(() {
                        _dlFrom = DateTime(now.year, now.month - 1, 1);
                        _dlTo = DateTime(now.year, now.month, 0);
                      });
                    }),
                  ],
                ),
                const SizedBox(height: 20),

                // Date pickers
                Row(
                  children: [
                    Expanded(child: _datePicker('FROM', _dlFrom, (d) {
                      setState(() => _dlFrom = d);
                    })),
                    const SizedBox(width: 12),
                    Expanded(child: _datePicker('TO', _dlTo, (d) {
                      setState(() => _dlTo = d);
                    })),
                  ],
                ),
                const SizedBox(height: 20),

                _label('TABLE'),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.inputBg,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: AppColors.inputBorder, width: 2),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _dlTable,
                      isExpanded: true,
                      icon: const Icon(Icons.expand_more_rounded),
                      items: [
                        const DropdownMenuItem(
                            value: 'all', child: Text('All Tables')),
                        ...['Reception 1', 'Reception 2'].map((t) =>
                            DropdownMenuItem(value: t, child: Text(t))),
                      ],
                      onChanged: (v) => setState(() => _dlTable = v!),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _generating ? null : _handleDownload,
                    icon: _generating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.picture_as_pdf_rounded, size: 20),
                    label: Text(_generating
                        ? 'Generating...'
                        : 'Download PDF Statement'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _datePicker(
      String label, DateTime value, ValueChanged<DateTime> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: value,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (picked != null) onChanged(picked);
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.inputBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.inputBorder, width: 2),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_rounded,
                    size: 18, color: AppColors.grey),
                const SizedBox(width: 8),
                Text(_dateFmt.format(value),
                    style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _periodChip(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.inputBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.inputBorder, width: 2),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.navy)),
      ),
    );
  }

  Widget _expenseItem(Expense e, {bool showTable = false}) {
    return ListTile(
      dense: true,
      title: Text(e.reason,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(
        '${showTable ? '${e.table} · ' : ''}${_timeFmt.format(e.date)}',
        style: const TextStyle(fontSize: 11, color: AppColors.grey),
      ),
      trailing: Text('-${_currFmt.format(e.amount)}',
          style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.red,
              fontSize: 15)),
    );
  }

  Widget _sectionTitle(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.navy),
          const SizedBox(width: 8),
          Text(text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
                letterSpacing: 0.3,
              )),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.grey,
          letterSpacing: 1,
        ),
      );
}
