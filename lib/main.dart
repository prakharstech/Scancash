import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/home_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/history_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/report_screen.dart';
import 'screens/validator_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ScanCashApp());
}

class ScanCashApp extends StatelessWidget {
  const ScanCashApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScanCash Pro',
      theme: AppTheme.dark(),
      debugShowCheckedModeBanner: false,
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _screens = const [
    HomeScreen(),
    HistoryScreen(),
    AnalyticsScreen(),
    ValidatorScreen(),
    ReportScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const ScanScreen()),
        ),
        backgroundColor: const Color(0xFF00C9A7),
        foregroundColor: Colors.black,
        child: const Icon(Icons.document_scanner_rounded, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF111827),
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(icon: Icons.home_rounded,       label: 'Home',      index: 0, current: _currentIndex, onTap: (i) => setState(() => _currentIndex = i)),
            _NavItem(icon: Icons.receipt_long_rounded, label: 'History',   index: 1, current: _currentIndex, onTap: (i) => setState(() => _currentIndex = i)),
            const SizedBox(width: 56), // FAB gap
            _NavItem(icon: Icons.bar_chart_rounded,   label: 'Analytics', index: 2, current: _currentIndex, onTap: (i) => setState(() => _currentIndex = i)),
            _NavItem(icon: Icons.picture_as_pdf_rounded, label: 'Reports', index: 4, current: _currentIndex, onTap: (i) => setState(() => _currentIndex = i)),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon; final String label;
  final int index, current; final Function(int) onTap;
  const _NavItem({required this.icon, required this.label, required this.index, required this.current, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final active = index == current;
    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: active ? const Color(0xFF00C9A7) : const Color(0xFF64748B), size: 22),
          Text(label, style: TextStyle(fontSize: 10, color: active ? const Color(0xFF00C9A7) : const Color(0xFF64748B), fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
        ]),
      ),
    );
  }
}