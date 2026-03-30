import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/db_helper.dart';
import '../theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, double> _summary = {};
  bool _loading = true;
  final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final s = await DBHelper.getGSTSummary();
    setState(() { _summary = s; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final totalGST = (_summary['cgst'] ?? 0) + (_summary['sgst'] ?? 0) + (_summary['igst'] ?? 0);
    return Scaffold(
      appBar: AppBar(
        title: const Text('ScanCash Pro'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.all(20), children: [
          // Hero card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0A1628), Color(0xFF0D2137)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.teal.withOpacity(0.3)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.teal.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.teal.withOpacity(0.4)),
                  ),
                  child: Text(DateFormat('MMMM yyyy').format(DateTime.now()),
                      style: const TextStyle(color: AppTheme.teal, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ]),
              const SizedBox(height: 12),
              const Text('Total Spend', style: TextStyle(color: Colors.white60, fontSize: 13)),
              Text(fmt.format(_summary['total'] ?? 0),
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 16),
              Row(children: [
                _MiniStat(label: 'Taxable', value: fmt.format(_summary['taxable'] ?? 0)),
                const SizedBox(width: 16),
                _MiniStat(label: 'GST (ITC)', value: fmt.format(totalGST), highlight: true),
              ]),
            ]),
          ),
          const SizedBox(height: 20),

          // GST breakdown cards
          const Text('GST Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(children: [
            _GSTCard(label: 'CGST', amount: _summary['cgst'] ?? 0, color: const Color(0xFF3B82F6)),
            const SizedBox(width: 10),
            _GSTCard(label: 'SGST', amount: _summary['sgst'] ?? 0, color: const Color(0xFF8B5CF6)),
            const SizedBox(width: 10),
            _GSTCard(label: 'IGST', amount: _summary['igst'] ?? 0, color: const Color(0xFFF59E0B)),
          ]),
          const SizedBox(height: 80),
        ]),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value; final bool highlight;
  const _MiniStat({required this.label, required this.value, this.highlight = false});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
    Text(value, style: TextStyle(color: highlight ? AppTheme.teal : Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
  ]);
}

class _GSTCard extends StatelessWidget {
  final String label; final double amount; final Color color;
  const _GSTCard({required this.label, required this.amount, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: AppTheme.muted, fontSize: 11)),
        Text('₹${amount.toStringAsFixed(0)}', style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w700)),
      ]),
    ),
  );
}