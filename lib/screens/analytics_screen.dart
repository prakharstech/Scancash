import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/db_helper.dart';
import '../theme.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  Map<String, double> _monthly = {}, _gst = {};
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final m = await DBHelper.getMonthlySummary();
    final g = await DBHelper.getGSTSummary();
    setState(() { _monthly = m; _gst = g; _loading = false; });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
      ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(padding: const EdgeInsets.all(20), children: [

      // Bar chart — monthly spend
      const Text('Monthly Spend', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      Container(
        height: 220,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.border)),
        child: _monthly.isEmpty
            ? const Center(child: Text('No data yet', style: TextStyle(color: AppTheme.muted)))
            : BarChart(BarChartData(
          gridData: FlGridData(show: true, drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => const FlLine(color: AppTheme.border, strokeWidth: 1)),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40,
                getTitlesWidget: (v, _) => Text('₹${(v/1000).toStringAsFixed(0)}k', style: const TextStyle(fontSize: 10, color: AppTheme.muted)))),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28,
                getTitlesWidget: (v, _) {
                  final keys = _monthly.keys.toList();
                  final idx = v.toInt();
                  if (idx < 0 || idx >= keys.length) return const SizedBox();
                  return Text(keys[idx].substring(5), style: const TextStyle(fontSize: 10, color: AppTheme.muted));
                })),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          barGroups: _monthly.entries.toList().asMap().entries.map((e) =>
              BarChartGroupData(x: e.key, barRods: [
                BarChartRodData(toY: e.value.value, color: AppTheme.teal, width: 20, borderRadius: BorderRadius.circular(6))
              ])
          ).toList(),
        )),
      ),
      const SizedBox(height: 24),

      // GST pie chart
      const Text('GST Component Split', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      Container(
        height: 240,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.border)),
        child: Row(children: [
          Expanded(
            child: PieChart(PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 50,
              sections: [
                if ((_gst['cgst'] ?? 0) > 0)
                  PieChartSectionData(value: _gst['cgst'], color: const Color(0xFF3B82F6), title: 'CGST', titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                if ((_gst['sgst'] ?? 0) > 0)
                  PieChartSectionData(value: _gst['sgst'], color: const Color(0xFF8B5CF6), title: 'SGST', titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                if ((_gst['igst'] ?? 0) > 0)
                  PieChartSectionData(value: _gst['igst'], color: AppTheme.amber, title: 'IGST', titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                if ((_gst['cgst'] ?? 0) == 0 && (_gst['sgst'] ?? 0) == 0 && (_gst['igst'] ?? 0) == 0)
                  PieChartSectionData(value: 1, color: AppTheme.border, title: 'No data'),
              ],
            )),
          ),
          Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            _Legend(const Color(0xFF3B82F6), 'CGST', '₹${(_gst["cgst"]??0).toStringAsFixed(0)}'),
            _Legend(const Color(0xFF8B5CF6), 'SGST', '₹${(_gst["sgst"]??0).toStringAsFixed(0)}'),
            _Legend(AppTheme.amber,             'IGST', '₹${(_gst["igst"]??0).toStringAsFixed(0)}'),
          ]),
        ]),
      ),
      const SizedBox(height: 80),
    ]),
  );
}

class _Legend extends StatelessWidget {
  final Color color; final String label, value;
  const _Legend(this.color, this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Text(label, style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
      const SizedBox(width: 8),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
    ]),
  );
}