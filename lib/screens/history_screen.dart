import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/db_helper.dart';
import '../models/gst_transaction.dart';
import '../theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<GSTTransaction> _txs = [];
  final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final txs = await DBHelper.getAll();
    setState(() => _txs = txs);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Transaction History'), actions: [
      IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
    ]),
    body: _txs.isEmpty
        ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.receipt_long_outlined, size: 64, color: AppTheme.muted),
      SizedBox(height: 12),
      Text('No transactions yet. Scan a receipt!', style: TextStyle(color: AppTheme.muted)),
    ]))
        : ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _txs.length,
      itemBuilder: (_, i) {
        final t = _txs[i];
        final totalGST = t.cgst + t.sgst + t.igst;
        return Dismissible(
          key: Key('${t.id}'),
          background: Container(
              alignment: Alignment.centerRight, color: AppTheme.red.withOpacity(0.8),
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.delete_rounded, color: Colors.white)),
          direction: DismissDirection.endToStart,
          onDismissed: (_) async {
            await DBHelper.delete(t.id!);
            setState(() => _txs.removeAt(i));
          },
          // --- FIXED: Wrapped the Card in the GestureDetector here ---
          child: GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: AppTheme.surface,
                  title: Text(t.vendorName),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Invoice: ${t.invoiceNo}'),
                      Text('GSTIN: ${t.gstin}'),
                      const Divider(),
                      Text('Taxable: ₹${t.taxableAmt.toStringAsFixed(2)}'),
                      Text('CGST: ₹${t.cgst.toStringAsFixed(2)}'),
                      Text('SGST: ₹${t.sgst.toStringAsFixed(2)}'),
                      Text('IGST: ₹${t.igst.toStringAsFixed(2)}'),
                    ],
                  ),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close', style: TextStyle(color: AppTheme.teal))
                    )
                  ],
                ),
              );
            },
            child: Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(color: AppTheme.teal.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.receipt_rounded, color: AppTheme.teal, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(t.vendorName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    Row(children: [
                      Text(t.invoiceDate, style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(color: AppTheme.teal.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                        child: Text(t.category, style: const TextStyle(color: AppTheme.teal, fontSize: 10)),
                      ),
                    ]),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(fmt.format(t.totalAmt), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    Text('GST: ${fmt.format(totalGST)}', style: const TextStyle(color: AppTheme.teal, fontSize: 11)),
                  ]),
                ]),
              ),
            ),
          ),
          // --- END OF FIX ---
        );
      },
    ),
  );
}