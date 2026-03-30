class GSTTransaction {
  final int? id;
  final String gstin, vendorName, invoiceNo, invoiceDate, category, txType;
  final double taxableAmt, cgst, sgst, igst, totalAmt, gstRate;

  const GSTTransaction({
    this.id,
    required this.gstin,
    required this.vendorName,
    required this.invoiceNo,
    required this.invoiceDate,
    required this.category,
    required this.taxableAmt,
    required this.cgst,
    required this.sgst,
    required this.igst,
    required this.totalAmt,
    required this.gstRate,
    required this.txType,
  });

  Map<String, dynamic> toMap() => {
    'gstin':        gstin,
    'vendor_name':  vendorName,
    'invoice_no':   invoiceNo,
    'invoice_date': invoiceDate,
    'category':     category,
    'taxable_amt':  taxableAmt,
    'cgst':         cgst,
    'sgst':         sgst,
    'igst':         igst,
    'total_amt':    totalAmt,
    'gst_rate':     gstRate,
    'tx_type':      txType,
  };

  factory GSTTransaction.fromMap(Map<String, dynamic> m) => GSTTransaction(
    id:          m['id'],
    gstin:       m['gstin'] ?? '',
    vendorName:  m['vendor_name'] ?? 'Unknown',
    invoiceNo:   m['invoice_no'] ?? '',
    invoiceDate: m['invoice_date'] ?? '',
    category:    m['category'] ?? 'General',
    taxableAmt:  (m['taxable_amt'] as num?)?.toDouble() ?? 0,
    cgst:        (m['cgst'] as num?)?.toDouble() ?? 0,
    sgst:        (m['sgst'] as num?)?.toDouble() ?? 0,
    igst:        (m['igst'] as num?)?.toDouble() ?? 0,
    totalAmt:    (m['total_amt'] as num?)?.toDouble() ?? 0,
    gstRate:     (m['gst_rate'] as num?)?.toDouble() ?? 0,
    txType:      m['tx_type'] ?? 'intra',
  );
}