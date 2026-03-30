import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:io';

class ParsedReceipt {
  final String? gstin, invoiceNo, date, vendorName;
  final double total, cgst, sgst, igst, taxableAmt;
  const ParsedReceipt({this.gstin, this.invoiceNo, this.date, this.vendorName,
    this.total = 0, this.cgst = 0, this.sgst = 0, this.igst = 0, this.taxableAmt = 0});
}

class OCRParser {
  static final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  static final _date = RegExp(r'\b(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{2,4})\b');

  static Future<ParsedReceipt> parse(String imagePath) async {
    final image = InputImage.fromFile(File(imagePath));
    final result = await _recognizer.processImage(image);

    final text = _reconstruct(result);
    // Flatten the entire receipt into one continuous line
    final flatText = text.replaceAll('\n', ' ').toUpperCase();
    final lines = text.split('\n');

    // --- 1. GSTIN ---
    final textNoSpaces = flatText.replaceAll(' ', '');
    final gstinMatch = RegExp(r'GSTIN[^A-Z0-9]*([A-Z0-9]{15})').firstMatch(textNoSpaces);
    final gstin = gstinMatch?.group(1);

    // --- 2. INVOICE NO ---
    final safeText = flatText.replaceAll(RegExp(r'TAX INVOICE'), '');
    final invMatch = RegExp(r'(?:BILL|INVOICE)\s*(?:NO\.?|#)\s*[:\-]?\s*([A-Z0-9\/\-]+)').firstMatch(safeText);
    final invoiceNo = invMatch?.group(1);

    // --- 3. DATE ---
    final date = _extractDate(text);

    // --- 4. BULLETPROOF GST EXTRACTION ---
    double cgst = _extractTax(flatText, 'CGST');
    double sgst = _extractTax(flatText, 'SGST');
    double igst = _extractTax(flatText, 'IGST');

    // --- 5. TOTAL AMOUNT ---
    double total = 0;
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (lower.contains('total') || lower.contains('net amount') || lower.contains('net amt') || lower.contains('grand')) {
        final val = _extractLastNumber(line) ?? 0;
        if (val > total) total = val;
      }
    }

    // --- 6. VENDOR NAME ---
    final vendorName = lines.firstWhere(
            (l) => l.isNotEmpty && l.length > 3 && !l.toUpperCase().contains('INVOICE'),
        orElse: () => ''
    ).trim();

    return ParsedReceipt(
      gstin: gstin, invoiceNo: invoiceNo, date: date,
      vendorName: vendorName, total: total,
      taxableAmt: total - cgst - sgst - igst,
      cgst: cgst, sgst: sgst, igst: igst,
    );
  }

  // --- NEW: Spatially-immune Tax Extractor ---
  static double _extractTax(String flatText, String taxType) {
    // Allows "C G S T" or "CGST"
    final labelPattern = taxType.split('').join(r'\s*');

    // Grabs everything between this tax label and the next major keyword
    final chunkRegex = RegExp(labelPattern + r'(.*?)(?:C\s*G\s*S\s*T|S\s*G\s*S\s*T|I\s*G\s*S\s*T|TOTAL|NET|AMOUNT|GRAND|ROUND|RO|$)', caseSensitive: false);
    final match = chunkRegex.firstMatch(flatText);

    if (match != null) {
      final cleanStr = match.group(1)!.replaceAll(',', '');
      final numMatches = RegExp(r'\b(\d+(?:\.\d+)?)\b').allMatches(cleanStr);
      if (numMatches.isNotEmpty) {
        // The actual amount is almost always the last number before the next label
        return double.tryParse(numMatches.last.group(1)!) ?? 0;
      }
    }
    return 0;
  }

  static double? _extractLastNumber(String line) {
    final cleanLine = line.replaceAll(',', '');
    final matches = RegExp(r'\b(\d+(?:\.\d+)?)\b').allMatches(cleanLine);
    if (matches.isNotEmpty) return double.tryParse(matches.last.group(1)!);
    return null;
  }

  static String _reconstruct(RecognizedText result) {
    List<TextElement> elements = [];
    for (var block in result.blocks) {
      for (var line in block.lines) {
        elements.addAll(line.elements);
      }
    }

    // Increased Y-tolerance to 25 to help keep slightly curved text on the same line
    elements.sort((a, b) {
      double diff = a.boundingBox.top - b.boundingBox.top;
      if (diff.abs() > 25) return diff.compareTo(0);
      return a.boundingBox.left.compareTo(b.boundingBox.left);
    });

    StringBuffer sb = StringBuffer();
    double lastY = -100;
    for (var el in elements) {
      if ((el.boundingBox.top - lastY).abs() > 25) {
        sb.write('\n');
        lastY = el.boundingBox.top;
      } else {
        sb.write(' ');
      }
      sb.write(el.text);
    }
    return sb.toString();
  }

  static String? _extractDate(String text) {
    final m = _date.firstMatch(text);
    if (m == null) return null;
    final y = m.group(3)!.length == 2 ? '20${m.group(3)}' : m.group(3)!;
    return '$y-${m.group(2)!.padLeft(2,'0')}-${m.group(1)!.padLeft(2,'0')}';
  }

  static void dispose() => _recognizer.close();
}