import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models.dart';

class PdfService {
  static final _currFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  static final _dateFmt = DateFormat('dd MMM yyyy');
  static const _navy = PdfColor.fromInt(0xFF16213E);
  static const _red = PdfColor.fromInt(0xFFC0392B);
  static const _green = PdfColor.fromInt(0xFF1E824C);
  static const _grey = PdfColor.fromInt(0xFF7A8BA8);
  static const _lightBg = PdfColor.fromInt(0xFFF0F3F8);

  static Future<void> generate({
    required List<Allotment> allotments,
    required List<Expense> expenses,
    required DateTime from,
    required DateTime to,
    required String selectedTable, // "all", "Reception 1", "Reception 2"
  }) async {
    final pdf = pw.Document();
    final tables = selectedTable == 'all'
        ? ['Reception 1', 'Reception 2']
        : [selectedTable];

    final fromStart = DateTime(from.year, from.month, from.day);
    final toEnd = DateTime(to.year, to.month, to.day, 23, 59, 59);

    double grandAllot = 0, grandSpent = 0;

    // Build table data
    final tableData = <Map<String, dynamic>>[];
    for (final table in tables) {
      final tAllot = allotments
          .where((a) =>
              a.table == table &&
              a.date.isAfter(fromStart.subtract(const Duration(seconds: 1))) &&
              a.date.isBefore(toEnd.add(const Duration(seconds: 1))))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      final tExp = expenses
          .where((e) =>
              e.table == table &&
              e.date.isAfter(fromStart.subtract(const Duration(seconds: 1))) &&
              e.date.isBefore(toEnd.add(const Duration(seconds: 1))))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      final totalAllot = tAllot.fold(0.0, (s, a) => s + a.amount);
      final totalSpent = tExp.fold(0.0, (s, e) => s + e.amount);
      grandAllot += totalAllot;
      grandSpent += totalSpent;

      tableData.add({
        'table': table,
        'allotments': tAllot,
        'expenses': tExp,
        'totalAllot': totalAllot,
        'totalSpent': totalSpent,
        'balance': totalAllot - totalSpent,
      });
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(from, to),
        footer: (context) => _buildFooter(context),
        build: (context) {
          final widgets = <pw.Widget>[];

          for (int i = 0; i < tableData.length; i++) {
            final td = tableData[i];
            widgets.add(_buildTableSection(td));
            if (i < tableData.length - 1) {
              widgets.add(pw.SizedBox(height: 16));
              widgets.add(pw.Divider(color: PdfColors.grey300));
              widgets.add(pw.SizedBox(height: 16));
            }
          }

          // Grand total
          if (tables.length > 1) {
            widgets.add(pw.SizedBox(height: 20));
            widgets.add(_buildGrandTotal(grandAllot, grandSpent));
          }

          return widgets;
        },
      ),
    );

    // Save and share
    final dir = await getTemporaryDirectory();
    final fileName =
        'PettyCash_${DateFormat('yyyy-MM-dd').format(from)}_to_${DateFormat('yyyy-MM-dd').format(to)}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Petty Cash Statement',
    );
  }

  static pw.Widget _buildHeader(DateTime from, DateTime to) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      margin: const pw.EdgeInsets.only(bottom: 24),
      decoration: pw.BoxDecoration(
        color: _navy,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Petty Cash Statement',
                  style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text(
                  'Period: ${_dateFmt.format(from)} — ${_dateFmt.format(to)}',
                  style: const pw.TextStyle(
                      color: PdfColors.grey300, fontSize: 9)),
            ],
          ),
          pw.Text('Generated: ${_dateFmt.format(DateTime.now())}',
              style:
                  const pw.TextStyle(color: PdfColors.grey400, fontSize: 8)),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 12),
      child: pw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
          style: const pw.TextStyle(color: _grey, fontSize: 8)),
    );
  }

  static pw.Widget _buildTableSection(Map<String, dynamic> td) {
    final allots = td['allotments'] as List<Allotment>;
    final exps = td['expenses'] as List<Expense>;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Table name header
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: pw.BoxDecoration(
            color: _lightBg,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(td['table'],
              style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: _navy)),
        ),
        pw.SizedBox(height: 12),

        // Summary row
        pw.Row(
          children: [
            _summaryBox('Total Allotted', td['totalAllot'], _navy),
            pw.SizedBox(width: 16),
            _summaryBox('Total Spent', td['totalSpent'], _red),
            pw.SizedBox(width: 16),
            _summaryBox('Balance', td['balance'],
                (td['balance'] as double) >= 0 ? _green : _red),
          ],
        ),
        pw.SizedBox(height: 16),

        // Allotments table
        if (allots.isNotEmpty) ...[
          pw.Text('ALLOTMENTS',
              style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: _grey)),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey200, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(1.5),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: _navy),
                children: [
                  _tableHeader('Date'),
                  _tableHeader('Amount', align: pw.TextAlign.right),
                ],
              ),
              ...allots.map((a) => pw.TableRow(
                    children: [
                      _tableCell(_dateFmt.format(a.date)),
                      _tableCell(_currFmt.format(a.amount),
                          align: pw.TextAlign.right),
                    ],
                  )),
            ],
          ),
          pw.SizedBox(height: 14),
        ],

        // Expenses table
        if (exps.isNotEmpty) ...[
          pw.Text('EXPENSES',
              style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: _grey)),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey200, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.5),
              1: const pw.FlexColumnWidth(3),
              2: const pw.FlexColumnWidth(1.5),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: _navy),
                children: [
                  _tableHeader('Date'),
                  _tableHeader('Reason'),
                  _tableHeader('Amount', align: pw.TextAlign.right),
                ],
              ),
              ...exps.asMap().entries.map((entry) {
                final e = entry.value;
                final isEven = entry.key % 2 == 0;
                return pw.TableRow(
                  decoration: isEven
                      ? const pw.BoxDecoration(color: _lightBg)
                      : null,
                  children: [
                    _tableCell(_dateFmt.format(e.date)),
                    _tableCell(e.reason),
                    _tableCell(_currFmt.format(e.amount),
                        align: pw.TextAlign.right, color: _red),
                  ],
                );
              }),
            ],
          ),
        ],

        if (allots.isEmpty && exps.isEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 12),
            child: pw.Text('No transactions in this period.',
                style: const pw.TextStyle(color: _grey, fontSize: 10)),
          ),
      ],
    );
  }

  static pw.Widget _summaryBox(String label, double amount, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey200),
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label,
                style: const pw.TextStyle(fontSize: 8, color: _grey)),
            pw.SizedBox(height: 4),
            pw.Text(_currFmt.format(amount),
                style: pw.TextStyle(
                    fontSize: 12, fontWeight: pw.FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildGrandTotal(double allot, double spent) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _navy,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('GRAND TOTAL',
              style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold)),
          pw.Row(children: [
            pw.Text('Allotted: ${_currFmt.format(allot)}  ',
                style: const pw.TextStyle(color: PdfColors.white, fontSize: 10)),
            pw.Text('Spent: ${_currFmt.format(spent)}  ',
                style: const pw.TextStyle(color: PdfColors.grey300, fontSize: 10)),
            pw.Text('Balance: ${_currFmt.format(allot - spent)}',
                style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold)),
          ]),
        ],
      ),
    );
  }

  static pw.Widget _tableHeader(String text, {pw.TextAlign? align}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(text,
          textAlign: align ?? pw.TextAlign.left,
          style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 8,
              fontWeight: pw.FontWeight.bold)),
    );
  }

  static pw.Widget _tableCell(String text,
      {pw.TextAlign? align, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: pw.Text(text,
          textAlign: align ?? pw.TextAlign.left,
          style: pw.TextStyle(fontSize: 9, color: color ?? _navy)),
    );
  }
}
