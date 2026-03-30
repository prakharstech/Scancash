import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/gst_transaction.dart';

class DBHelper {
  static Database? _db;

  static Future<Database> get db async {
    _db ??= await _init();
    return _db!;
  }

  static Future<Database> _init() async {
    final path = join(await getDatabasesPath(), 'scancash.db');
    return openDatabase(path, version: 1, onCreate: (db, v) async {
      await db.execute('''
        CREATE TABLE gst_transactions (
          id           INTEGER PRIMARY KEY AUTOINCREMENT,
          gstin        TEXT,
          vendor_name  TEXT,
          invoice_no   TEXT,
          invoice_date TEXT,
          category     TEXT,
          taxable_amt  REAL DEFAULT 0,
          cgst         REAL DEFAULT 0,
          sgst         REAL DEFAULT 0,
          igst         REAL DEFAULT 0,
          total_amt    REAL DEFAULT 0,
          gst_rate     REAL DEFAULT 0,
          tx_type      TEXT DEFAULT 'intra',
          created_at   TEXT DEFAULT (datetime('now'))
        )
      ''');
    });
  }

  static Future<int> insert(GSTTransaction tx) async {
    final d = await db;
    return d.insert('gst_transactions', tx.toMap());
  }

  static Future<List<GSTTransaction>> getAll() async {
    final d = await db;
    final rows = await d.query('gst_transactions', orderBy: 'created_at DESC');
    return rows.map(GSTTransaction.fromMap).toList();
  }

  static Future<List<GSTTransaction>> getByMonth(String yearMonth) async {
    final d = await db;
    final rows = await d.query('gst_transactions',
        where: "invoice_date LIKE ?", whereArgs: ['$yearMonth%'],
        orderBy: 'invoice_date DESC');
    return rows.map(GSTTransaction.fromMap).toList();
  }

  static Future<Map<String, double>> getMonthlySummary() async {
    final d = await db;
    final rows = await d.rawQuery('''
      SELECT strftime('%Y-%m', invoice_date) as month,
             SUM(total_amt) as total
      FROM gst_transactions
      GROUP BY month ORDER BY month DESC LIMIT 6
    ''');
    return { for (var r in rows) r['month'] as String: (r['total'] as num).toDouble() };
  }

  static Future<Map<String, double>> getGSTSummary() async {
    final d = await db;
    final r = await d.rawQuery('SELECT SUM(taxable_amt) t, SUM(cgst) c, SUM(sgst) s, SUM(igst) i, SUM(total_amt) tot FROM gst_transactions');
    final row = r.first;
    return {
      'taxable': (row['t'] as num?)?.toDouble() ?? 0,
      'cgst':    (row['c'] as num?)?.toDouble() ?? 0,
      'sgst':    (row['s'] as num?)?.toDouble() ?? 0,
      'igst':    (row['i'] as num?)?.toDouble() ?? 0,
      'total':   (row['tot'] as num?)?.toDouble() ?? 0,
    };
  }

  static Future<void> delete(int id) async {
    final d = await db;
    await d.delete('gst_transactions', where: 'id = ?', whereArgs: [id]);
  }
}