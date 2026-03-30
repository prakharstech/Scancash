import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart'; // Re-added this for font loading
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../models/gst_transaction.dart';
import 'package:intl/intl.dart';

class PDFService {
  static Future<void> generateAndShare(List<GSTTransaction> txList, String monthLabel) async {
    final pdf = pw.Document();

    // --- NEW: Load Unicode Fonts ---
    // This allows the Rupee symbol (₹) to render correctly
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();

    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    double totTaxable=0, totCgst=0, totSgst=0, totIgst=0, totTotal=0;
    for (final t in txList) {
      totTaxable += t.taxableAmt; totCgst += t.cgst;
      totSgst    += t.sgst;       totIgst += t.igst;
      totTotal   += t.totalAmt;
    }

    pdf.addPage(pw.MultiPage(
      // --- NEW: Apply the font theme ---
      theme: pw.ThemeData.withFont(
        base: font,
        bold: boldFont,
      ),
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (ctx) => [
        // Header
        pw.Container(
          color: PdfColor.fromHex('#0A1628'),
          padding: const pw.EdgeInsets.all(20),
          child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('ScanCash Pro', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
              pw.Text('GST Expense Report — $monthLabel', style: pw.TextStyle(fontSize: 11, color: PdfColors.grey300)),
            ]),
            pw.Text('Generated: ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
                style: pw.TextStyle(fontSize: 9, color: PdfColors.grey400)),
          ]),
        ),
        pw.SizedBox(height: 16),

        // Summary row
        pw.Row(children: [
          _summaryCard('Total Invoices', '${txList.length}'),
          pw.SizedBox(width: 8),
          _summaryCard('Total GST (ITC)', fmt.format(totCgst + totSgst + totIgst)),
          pw.SizedBox(width: 8),
          _summaryCard('Total Spend', fmt.format(totTotal)),
        ]),
        pw.SizedBox(height: 16),

        // Table
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(3),
            2: const pw.FlexColumnWidth(1.5),
            3: const pw.FlexColumnWidth(1.5),
            4: const pw.FlexColumnWidth(1.5),
            5: const pw.FlexColumnWidth(1.5),
            6: const pw.FlexColumnWidth(2),
          },
          children: [
            _tableHeader(['Date', 'Vendor', 'Taxable', 'CGST', 'SGST', 'IGST', 'Total']),
            ...txList.map((t) => _tableRow([
              t.invoiceDate, t.vendorName,
              fmt.format(t.taxableAmt), fmt.format(t.cgst),
              fmt.format(t.sgst), fmt.format(t.igst),
              fmt.format(t.totalAmt),
            ])),
            _totalRow([
              'TOTAL', '',
              fmt.format(totTaxable), fmt.format(totCgst),
              fmt.format(totSgst), fmt.format(totIgst),
              fmt.format(totTotal),
            ]),
          ],
        ),
      ],
    ));

    final dir  = await getTemporaryDirectory();
    final file = File('${dir.path}/GST_Report_$monthLabel.pdf');
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(file.path)], subject: 'GST Report $monthLabel');
  }

  static pw.Widget _summaryCard(String label, String val) => pw.Expanded(
    child: pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(color: PdfColor.fromHex('#EFF6FF'), borderRadius: pw.BorderRadius.circular(6)),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        pw.Text(val,   style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
      ]),
    ),
  );

  static pw.TableRow _tableHeader(List<String> cols) => pw.TableRow(
    decoration: pw.BoxDecoration(color: PdfColor.fromHex('#1E3A5F')),
    children: cols.map((c) => pw.Padding(padding: const pw.EdgeInsets.all(6),
        child: pw.Text(c, style: pw.TextStyle(fontSize: 9, color: PdfColors.white, fontWeight: pw.FontWeight.bold))
    )).toList(),
  );

  static pw.TableRow _tableRow(List<String> cols) => pw.TableRow(
    children: cols.map((c) => pw.Padding(padding: const pw.EdgeInsets.all(6),
        child: pw.Text(c, style: const pw.TextStyle(fontSize: 9))
    )).toList(),
  );

  static pw.TableRow _totalRow(List<String> cols) => pw.TableRow(
    decoration: pw.BoxDecoration(color: PdfColor.fromHex('#FEF3C7')),
    children: cols.map((c) => pw.Padding(padding: const pw.EdgeInsets.all(6),
        child: pw.Text(c, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))
    )).toList(),
  );
}