import 'package:http/http.dart' as http;
import 'dart:convert';

class GSTINResult {
  final bool isValid;
  final String? legalName, tradeName, status, stateCode, taxpayerType;
  final String? error;
  const GSTINResult({required this.isValid, this.legalName, this.tradeName,
    this.status, this.stateCode, this.taxpayerType, this.error});
}

class GSTINValidator {
  static const _key = 'KNQzTuUyVjSnENdVaQWBfEzvEzY2';
  static const _url = 'https://appyflow.in/api/verifyGST';

  // Map of state codes to state names
  static const _states = {
    '01':'Jammu & Kashmir', '02':'Himachal Pradesh', '03':'Punjab',
    '04':'Chandigarh',       '06':'Haryana',          '07':'Delhi',
    '08':'Rajasthan',        '09':'Uttar Pradesh',    '10':'Bihar',
    '11':'Sikkim',            '12':'Arunachal Pradesh', '13':'Nagaland',
    '16':'West Bengal',       '17':'Jharkhand',         '18':'Assam',
    '19':'Odisha',             '20':'Jharkhand',         '21':'Odisha',
    '22':'Chhattisgarh',      '23':'Madhya Pradesh',    '24':'Gujarat',
    '27':'Maharashtra',       '29':'Karnataka',         '32':'Kerala',
    '33':'Tamil Nadu',        '36':'Telangana',          '37':'Andhra Pradesh',
  };

  static String getState(String gstin) =>
      _states[gstin.substring(0, 2)] ?? 'Unknown State';

  static bool isValidFormat(String g) =>
      RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$').hasMatch(g);

  static Future<GSTINResult> validate(String gstin) async {
    final g = gstin.trim().toUpperCase();
    if (!isValidFormat(g)) return const GSTINResult(isValid: false, error: 'Invalid GSTIN format');
    try {
      final uri = Uri.parse('$_url?gstNo=$g&key_secret=$_key');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return GSTINResult(isValid: false, error: 'API error ${res.statusCode}');
      final json = jsonDecode(res.body);
      final info = json['taxpayerInfo'];
      if (info == null) return GSTINResult(isValid: false, error: json['message'] ?? 'Not found');
      return GSTINResult(
        isValid:     info['sts'] == 'Active',
        legalName:   info['lgnm'],
        tradeName:   info['tradeNam'],
        status:      info['sts'],
        stateCode:   g.substring(0, 2),
        taxpayerType: info['ctb'],
      );
    } catch (e) {
      return GSTINResult(isValid: false, error: 'Network error: $e');
    }
  }
}