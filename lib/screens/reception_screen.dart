import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../main.dart';
import '../models.dart';
import '../services/storage_service.dart';
import 'login_screen.dart';

class ReceptionScreen extends StatefulWidget {
  final String table;
  final String roleName;

  const ReceptionScreen({
    super.key,
    required this.table,
    required this.roleName,
  });

  @override
  State<ReceptionScreen> createState() => _ReceptionScreenState();
}

class _ReceptionScreenState extends State<ReceptionScreen> {
  List<Allotment> _allotments = [];
  List<Expense> _expenses = [];
  bool _loading = true;
  StreamSubscription? _allotmentsSub;
  StreamSubscription? _expensesSub;

  final _amountCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  final _reasonFocus = FocusNode();

  final _currFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  final _dateFmt = DateFormat('dd MMM yyyy');
  final _timeFmt = DateFormat('hh:mm a');

  @override
  void initState() {
    super.initState();
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

  double get _balance {
    final allotted = _allotments
        .where((a) => a.table == widget.table)
        .fold(0.0, (s, a) => s + a.amount);
    final spent = _expenses
        .where((e) => e.table == widget.table)
        .fold(0.0, (s, e) => s + e.amount);
    return allotted - spent;
  }

  double get _totalAllotted => _allotments
      .where((a) => a.table == widget.table)
      .fold(0.0, (s, a) => s + a.amount);

  double get _totalSpent => _expenses
      .where((e) => e.table == widget.table)
      .fold(0.0, (s, e) => s + e.amount);

  List<Expense> get _myExpenses => _expenses
      .where((e) => e.table == widget.table)
      .toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  List<Expense> get _todayExpenses {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _myExpenses
        .where((e) => DateFormat('yyyy-MM-dd').format(e.date) == todayStr)
        .toList();
  }

  void _handleExpense() {
    final amt = double.tryParse(_amountCtrl.text);
    if (amt == null || amt <= 0) {
      _showSnack('Enter a valid amount', isError: true);
      return;
    }
    if (_reasonCtrl.text.trim().isEmpty) {
      _showSnack('Enter a reason', isError: true);
      return;
    }
    if (amt > _balance) {
      _showSnack('Insufficient balance!', isError: true);
      return;
    }

    final expense = Expense(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      table: widget.table,
      amount: amt,
      reason: _reasonCtrl.text.trim(),
    );

    StorageService.addExpense(expense);
    _amountCtrl.clear();
    _reasonCtrl.clear();
    _showSnack('${_currFmt.format(amt)} recorded');
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
    _amountCtrl.dispose();
    _reasonCtrl.dispose();
    _reasonFocus.dispose();
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
              child: Text(widget.roleName,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 20),
            onPressed: () => Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const LoginScreen())),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── Balance Card ───
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A3A5C), Color(0xFF16213E)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFF1A3A5C).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Available Balance',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(_currFmt.format(_balance),
                      style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
                const SizedBox(height: 8),
                Text(
                  'Allotted: ${_currFmt.format(_totalAllotted)}  ·  Spent: ${_currFmt.format(_totalSpent)}',
                  style: TextStyle(
                      fontSize: 11, color: Colors.white.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ─── Low balance warnings ───
          if (_balance > 0 && _balance < 500)
            _warningBanner(
              Colors.orange.shade50,
              Colors.orange.shade800,
              Icons.warning_amber_rounded,
              'Low balance! Only ${_currFmt.format(_balance)} remaining.',
            ),
          if (_balance <= 0)
            _warningBanner(
              Colors.red.shade50,
              AppColors.red,
              Icons.error_outline_rounded,
              'No balance available. Contact Admin for allotment.',
            ),

          // ─── Expense Entry ───
          _sectionTitle(Icons.add_circle_outline_rounded, 'Record Expense'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('AMOUNT (₹)'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(
                      hintText: 'Enter amount',
                      prefixText: '₹ ',
                    ),
                    onSubmitted: (_) => _reasonFocus.requestFocus(),
                  ),
                  const SizedBox(height: 16),
                  _label('REASON'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _reasonCtrl,
                    focusNode: _reasonFocus,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Courier charges, Stationery',
                    ),
                    onSubmitted: (_) => _handleExpense(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _balance > 0 ? _handleExpense : null,
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text('Add Expense'),
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
          const SizedBox(height: 8),

          // ─── Today's Expenses ───
          _sectionTitle(Icons.receipt_long_rounded,
              "Today's Expenses (${_todayExpenses.length})"),
          Card(
            child: _todayExpenses.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                        child: Text('No expenses today',
                            style: TextStyle(color: AppColors.grey))))
                : Column(
                    children:
                        _todayExpenses.map((e) => _expenseItem(e)).toList()),
          ),
          const SizedBox(height: 8),

          // ─── All Expenses ───
          _sectionTitle(
              Icons.history_rounded, 'Recent Expenses (${_myExpenses.length})'),
          Card(
            child: _myExpenses.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                        child: Text('No expenses recorded yet',
                            style: TextStyle(color: AppColors.grey))))
                : Column(
                    children: _myExpenses
                        .take(20)
                        .map((e) => _expenseItem(e, showDate: true))
                        .toList()),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _expenseItem(Expense e, {bool showDate = false}) {
    return ListTile(
      dense: true,
      title: Text(e.reason,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(
        showDate
            ? _dateFmt.format(e.date)
            : _timeFmt.format(e.date),
        style: const TextStyle(fontSize: 11, color: AppColors.grey),
      ),
      trailing: Text('-${_currFmt.format(e.amount)}',
          style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.red,
              fontSize: 15)),
    );
  }

  Widget _warningBanner(
      Color bg, Color fg, IconData icon, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg, size: 20),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: TextStyle(
                      fontSize: 12, color: fg, fontWeight: FontWeight.w500))),
        ],
      ),
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
