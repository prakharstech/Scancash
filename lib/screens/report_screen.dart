import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/db_helper.dart';
import '../services/pdf_service.dart';
import '../models/gst_transaction.dart';
import '../theme.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});
  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
  List<GSTTransaction> _txs = [];
  bool _loading = false, _generating = false;
  final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final txs = await DBHelper.getByMonth(_selectedMonth);
    setState(() { _txs = txs; _loading = false; });
  }

  double get _totalAmt   => _txs.fold(0, (s, t) => s + t.totalAmt);
  double get _totalGST   => _txs.fold(0, (s, t) => s + t.cgst + t.sgst + t.igst);
  double get _totalCGST  => _txs.fold(0, (s, t) => s + t.cgst);
  double get _totalSGST  => _txs.fold(0, (s, t) => s + t.sgst);
  double get _totalIGST  => _txs.fold(0, (s, t) => s + t.igst);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('GST Report')),
    body: Column(children: [
      // Month selector
      Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                    context: context, initialDate: DateTime.now(),
                    firstDate: DateTime(2023), lastDate: DateTime.now(),
                    builder: (ctx, child) => Theme(
                        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.dark(primary: AppTheme.teal)),
                        child: child!));
                if (picked != null) {
                  setState(() => _selectedMonth = DateFormat('yyyy-MM').format(picked));
                  _load();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
                child: Row(children: [
                  const Icon(Icons.calendar_month, color: AppTheme.teal, size: 18),
                  const SizedBox(width: 8),
                  Text(_selectedMonth, style: const TextStyle(fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _generating || _txs.isEmpty ? null : () async {
              setState(() => _generating = true);
              await PDFService.generateAndShare(_txs, _selectedMonth);
              setState(() => _generating = false);
            },
            icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
            label: Text(_generating ? 'Generating...' : 'Export PDF'),
          ),
        ]),
      ),

      // Summary row
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          _SummaryTile('Invoices', '${_txs.length}'),
          const SizedBox(width: 8),
          _SummaryTile('Total GST', fmt.format(_totalGST), color: AppTheme.teal),
          const SizedBox(width: 8),
          _SummaryTile('Total Spend', fmt.format(_totalAmt)),
        ]),
      ),
      const SizedBox(height: 12),

      // Table header
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: const Color(0xFF1E3A5F), borderRadius: BorderRadius.circular(8)),
          child: const Row(children: [
            Expanded(flex: 2, child: Text('Vendor',   style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600))),
            Expanded(flex: 1, child: Text('CGST',    style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
            Expanded(flex: 1, child: Text('SGST',    style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
            Expanded(flex: 1, child: Text('IGST',    style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
            Expanded(flex: 1, child: Text('Total',   style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
          ]),
        ),
      ),
      const SizedBox(height: 4),

      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _txs.isEmpty
            ? const Center(child: Text('No transactions for this month', style: TextStyle(color: AppTheme.muted)))
            : ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _txs.length,
          itemBuilder: (_, i) {
            final t = _txs[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: i.isEven ? AppTheme.card : AppTheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(children: [
                Expanded(flex: 2, child: Text(t.vendorName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                Expanded(flex: 1, child: Text('₹${t.cgst.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: Color(0xFF3B82F6)), textAlign: TextAlign.right)),
                Expanded(flex: 1, child: Text('₹${t.sgst.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: Color(0xFF8B5CF6)), textAlign: TextAlign.right)),
                Expanded(flex: 1, child: Text('₹${t.igst.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: AppTheme.amber), textAlign: TextAlign.right)),
                Expanded(flex: 1, child: Text('₹${t.totalAmt.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700), textAlign: TextAlign.right)),
              ]),
            );
          },
        ),
      ),
    ]),
  );
}

class _SummaryTile extends StatelessWidget {
  final String label, value; final Color? color;
  const _SummaryTile(this.label, this.value, {this.color});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: AppTheme.muted, fontSize: 10)),
        Text(value, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: color ?? Colors.white)),
      ]),
    ),
  );
}