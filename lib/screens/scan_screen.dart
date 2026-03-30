import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/ocr_parser.dart';
import '../theme.dart';
import 'result_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});
  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  File? _image;
  bool _processing = false;
  String _status = '';

  Future<void> _pick(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 90);
    if (picked == null) return;

    setState(() { _image = File(picked.path); _processing = true; _status = 'Scanning receipt...'; });

    try {
      setState(() => _status = 'Extracting text with ML Kit...');
      final parsed = await OCRParser.parse(picked.path);

      if (!mounted) return;
      await Navigator.push(context,
          MaterialPageRoute(builder: (_) => ResultScreen(parsed: parsed, imagePath: picked.path)));
    } catch (e) {
      setState(() => _status = 'Error: $e');
    } finally {
      setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Scan Receipt')),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        // Preview
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: _image != null
                ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(_image!, fit: BoxFit.contain))
                : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.receipt_long, size: 64, color: AppTheme.muted),
              SizedBox(height: 12),
              Text('Capture a receipt to begin', style: TextStyle(color: AppTheme.muted)),
            ]),
          ),
        ),
        if (_processing) ...[
          const SizedBox(height: 16),
          const CircularProgressIndicator(color: AppTheme.teal),
          const SizedBox(height: 8),
          Text(_status, style: const TextStyle(color: AppTheme.muted)),
        ],
        const SizedBox(height: 20),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _pick(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_rounded),
              label: const Text('Gallery'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.teal,
                side: const BorderSide(color: AppTheme.teal),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _pick(ImageSource.camera),
              icon: const Icon(Icons.camera_alt_rounded),
              label: const Text('Camera'),
            ),
          ),
        ]),
      ]),
    ),
  );
}