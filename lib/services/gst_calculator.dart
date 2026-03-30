class GSTBreakdown {
  final double taxableBase, cgst, sgst, igst, total, effectiveRate;
  final String txType;
  const GSTBreakdown({required this.taxableBase, required this.cgst,
    required this.sgst, required this.igst, required this.total,
    required this.effectiveRate, required this.txType});
}

class GSTCalculator {
  /// If OCR already found CGST/SGST/IGST lines, use those directly.
  /// Otherwise, compute from total and buyer vs supplier state codes.
  static GSTBreakdown compute({
    required double invoiceTotal,
    double ocrCgst = 0, double ocrSgst = 0, double ocrIgst = 0,
    String? buyerStateCode,    // First 2 chars of YOUR GSTIN
    String? supplierStateCode, // From validated supplier GSTIN
  }) {
    final totalGST = ocrCgst + ocrSgst + ocrIgst;

    // If OCR found specific components, use them
    if (totalGST > 0) {
      final taxable = invoiceTotal - totalGST;
      return GSTBreakdown(
        taxableBase: taxable, cgst: ocrCgst, sgst: ocrSgst, igst: ocrIgst,
        total: invoiceTotal,
        effectiveRate: taxable > 0 ? (totalGST / taxable) * 100 : 0,
        txType: ocrIgst > 0 ? 'inter' : 'intra',
      );
    }

    // Fallback: derive from state code comparison
    // Assume 18% GST rate if we can't determine — most common in India
    const defaultRate = 18.0;
    final gstAmount  = invoiceTotal * defaultRate / (100 + defaultRate);
    final taxable    = invoiceTotal - gstAmount;
    final isIntra    = buyerStateCode != null && supplierStateCode != null
        && buyerStateCode == supplierStateCode;
    return GSTBreakdown(
      taxableBase: taxable,
      cgst:  isIntra ? gstAmount / 2 : 0,
      sgst:  isIntra ? gstAmount / 2 : 0,
      igst:  isIntra ? 0 : gstAmount,
      total: invoiceTotal,
      effectiveRate: defaultRate,
      txType: isIntra ? 'intra' : 'inter',
    );
  }
}