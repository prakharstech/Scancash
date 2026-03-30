import 'package:flutter/material.dart';
import '../services/ocr_parser.dart';
import '../services/gstin_validator.dart';
import '../services/gst_calculator.dart';
import '../services/db_helper.dart';
import '../models/gst_transaction.dart';
import '../theme.dart';

class ResultScreen extends StatefulWidget {
  final ParsedReceipt parsed;
  final String imagePath;
  const ResultScreen({super.key, required this.parsed, required this.imagePath});
  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late final _gstinCtrl  = TextEditingController(text: widget.parsed.gstin ?? '');
  late final _vendorCtrl = TextEditingController(text: widget.parsed.vendorName ?? '');
  late final _dateCtrl   = TextEditingController(text: widget.parsed.date ?? '');
  late final _totalCtrl  = TextEditingController(text: widget.parsed.total.toStringAsFixed(2));
  late final _invCtrl    = TextEditingController(text: widget.parsed.invoiceNo ?? '');
  String _category = 'General';
  GSTINResult? _gstResult;
  GSTBreakdown? _breakdown;
  bool _validating = false, _saving = false;

  static const _categories = ['General', 'Food', 'Travel', 'Office', 'Medical', 'Utilities'];

  @override
  void initState() {
    super.initState();
    // Auto-compute breakdown from OCR data
    _breakdown = GSTCalculator.compute(
      invoiceTotal: widget.parsed.total,
      ocrCgst: widget.parsed.cgst, ocrSgst: widget.parsed.sgst, ocrIgst: widget.parsed.igst,
    );
    // Auto-validate if GSTIN found
    if (widget.parsed.gstin != null) _validateGSTIN();
  }

  Future<void> _validateGSTIN() async {
    setState(() => _validating = true);
    final result = await GSTINValidator.validate(_gstinCtrl.text);
    setState(() {
      _gstResult = result;
      _validating = false;
      if (result.legalName != null && _vendorCtrl.text.isEmpty) {
        _vendorCtrl.text = result.legalName!;
      }
    });
  }

  Future<void> _save() async {
    final bd = _breakdown!;
    final tx = GSTTransaction(
      gstin:       _gstinCtrl.text,
      vendorName:  _vendorCtrl.text.isEmpty ? 'Unknown' : _vendorCtrl.text,
      invoiceNo:   _invCtrl.text,
      invoiceDate: _dateCtrl.text,
      category:    _category,
      taxableAmt:  bd.taxableBase,
      cgst:        bd.cgst, sgst: bd.sgst, igst: bd.igst,
      totalAmt:    double.tryParse(_totalCtrl.text) ?? bd.total,
      gstRate:     bd.effectiveRate,
      txType:      bd.txType,
    );
    setState(() => _saving = true);
    await DBHelper.insert(tx);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Transaction saved!'), backgroundColor: AppTheme.teal));
      Navigator.pop(context);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Review Receipt')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      // GSTIN row with validate button
      Row(children: [
        Expanded(child: TextField(controller: _gstinCtrl,
            decoration: const InputDecoration(labelText: 'GSTIN', prefixIcon: Icon(Icons.verified_rounded)),
            style: const TextStyle(fontFamily: 'monospace', letterSpacing: 1))),
        const SizedBox(width: 8),
        _validating
            ? const CircularProgressIndicator(color: AppTheme.teal)
            : IconButton(
            onPressed: _validateGSTIN,
            icon: const Icon(Icons.search),
            color: AppTheme.teal,
            tooltip: 'Validate GSTIN'),
      ]),

      // Validation result badge
      if (_gstResult != null) ...[
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (_gstResult!.isValid ? AppTheme.teal : AppTheme.red).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: (_gstResult!.isValid ? AppTheme.teal : AppTheme.red).withOpacity(0.3)),
          ),
          child: Row(children: [
            Icon(_gstResult!.isValid ? Icons.check_circle : Icons.cancel,
                color: _gstResult!.isValid ? AppTheme.teal : AppTheme.red, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(
              _gstResult!.isValid
                  ? '${_gstResult!.legalName} • ${_gstResult!.status} • ${GSTINValidator.getState(_gstinCtrl.text)}'
                  : _gstResult!.error ?? 'Invalid GSTIN',
              style: TextStyle(fontSize: 12, color: _gstResult!.isValid ? AppTheme.teal : AppTheme.red),
            )),
          ]),
        ),
      ],
      const SizedBox(height: 12),

      TextField(controller: _vendorCtrl, decoration: const InputDecoration(labelText: 'Vendor Name', prefixIcon: Icon(Icons.store_rounded))),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: TextField(controller: _dateCtrl, decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)'))),
        const SizedBox(width: 12),
        Expanded(child: TextField(controller: _invCtrl,  decoration: const InputDecoration(labelText: 'Invoice No.'))),
      ]),
      const SizedBox(height: 12),
      TextField(controller: _totalCtrl, keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Total Amount (₹)', prefixIcon: Icon(Icons.currency_rupee))),
      const SizedBox(height: 12),

      // Category picker
      DropdownButtonFormField<String>(
        value: _category,
        decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category_rounded)),
        dropdownColor: AppTheme.card,
        items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
        onChanged: (v) => setState(() => _category = v!),
      ),
      const SizedBox(height: 20),

      // GST breakdown card
      if (_breakdown != null)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('GST Breakdown (${_breakdown!.txType == "intra" ? "Intra-State" : "Inter-State"})',
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.teal)),
            const Divider(height: 16),
            _BDRow('Taxable Amount', '₹${_breakdown!.taxableBase.toStringAsFixed(2)}'),
            _BDRow('CGST',           '₹${_breakdown!.cgst.toStringAsFixed(2)}', color: const Color(0xFF3B82F6)),
            _BDRow('SGST',           '₹${_breakdown!.sgst.toStringAsFixed(2)}', color: const Color(0xFF8B5CF6)),
            _BDRow('IGST',           '₹${_breakdown!.igst.toStringAsFixed(2)}', color: AppTheme.amber),
            const Divider(height: 12),
            _BDRow('Effective GST Rate', '${_breakdown!.effectiveRate.toStringAsFixed(1)}%', bold: true),
          ]),
        ),
      const SizedBox(height: 24),
      ElevatedButton(
        onPressed: _saving ? null : _save,
        child: _saving ? const CircularProgressIndicator(color: Colors.black, strokeWidth: 2)
            : const Text('Save Transaction'),
      ),
    ]),
  );
}

class _BDRow extends StatelessWidget {
  final String label, value; final Color? color; final bool bold;
  const _BDRow(this.label, this.value, {this.color, this.bold = false});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: AppTheme.muted, fontSize: 13, fontWeight: bold ? FontWeight.w700 : FontWeight.normal)),
      Text(value, style: TextStyle(color: color ?? Colors.white, fontSize: 13, fontWeight: bold ? FontWeight.w700 : FontWeight.normal)),
    ]),
  );
}