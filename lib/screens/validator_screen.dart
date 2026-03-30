import 'package:flutter/material.dart';
import '../services/gstin_validator.dart';
import '../theme.dart';

class ValidatorScreen extends StatefulWidget {
  const ValidatorScreen({super.key});
  @override
  State<ValidatorScreen> createState() => _ValidatorScreenState();
}

class _ValidatorScreenState extends State<ValidatorScreen> {
  final _ctrl = TextEditingController();
  GSTINResult? _result;
  bool _loading = false;

  Future<void> _validate() async {
    if (_ctrl.text.isEmpty) return;
    setState(() { _loading = true; _result = null; });
    final r = await GSTINValidator.validate(_ctrl.text);
    setState(() { _result = r; _loading = false; });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('GSTIN Validator')),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        TextField(
          controller: _ctrl,
          decoration: const InputDecoration(
            labelText: 'Enter GSTIN (15 characters)',
            prefixIcon: Icon(Icons.verified_rounded),
          ),
          maxLength: 15,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(fontFamily: 'monospace', letterSpacing: 2, fontSize: 16),
        ),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _validate,
            child: _loading ? const CircularProgressIndicator(color: Colors.black, strokeWidth: 2)
                : const Text('Validate via AppyFlow API'),
          ),
        ),
        const SizedBox(height: 24),
        if (_result != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: (_result!.isValid ? AppTheme.teal : AppTheme.red).withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: (_result!.isValid ? AppTheme.teal : AppTheme.red).withOpacity(0.3)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(_result!.isValid ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: _result!.isValid ? AppTheme.teal : AppTheme.red),
                const SizedBox(width: 8),
                Text(_result!.isValid ? 'Valid & Active' : 'Invalid / Not Found',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16,
                        color: _result!.isValid ? AppTheme.teal : AppTheme.red)),
              ]),
              if (_result!.isValid) ...[
                const Divider(height: 20),
                _InfoRow('Legal Name',    _result!.legalName ?? '-'),
                _InfoRow('Trade Name',    _result!.tradeName ?? '-'),
                _InfoRow('Status',        _result!.status ?? '-'),
                _InfoRow('State',         GSTINValidator.getState(_ctrl.text)),
                _InfoRow('Taxpayer Type', _result!.taxpayerType ?? '-'),
              ] else
                Text(_result!.error ?? '', style: const TextStyle(color: AppTheme.red, fontSize: 13)),
            ]),
          ),
      ]),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      SizedBox(width: 120, child: Text(label, style: const TextStyle(color: AppTheme.muted, fontSize: 13))),
      Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
    ]),
  );
}