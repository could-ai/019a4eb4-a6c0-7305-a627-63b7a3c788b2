import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pdf_text/pdf_text.dart';

class PdfAnalyzeScreen extends StatefulWidget {
  const PdfAnalyzeScreen({super.key});

  @override
  State<PdfAnalyzeScreen> createState() => _PdfAnalyzeScreenState();
}

class _PdfAnalyzeScreenState extends State<PdfAnalyzeScreen> {
  File? _pdfFile;
  String _extractedText = '';
  String _summary = '';
  bool _isProcessing = false;

  Future<void> _pickPdf() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null) {
      setState(() {
        _pdfFile = File(result.files.single.path!);
      });
      _extractText();
    }
  }

  Future<void> _extractText() async {
    if (_pdfFile == null) return;

    setState(() {
      _isProcessing = true;
    });

    PDFDoc doc = await PDFDoc.fromFile(_pdfFile!);
    String text = await doc.text;

    setState(() {
      _extractedText = text;
      _isProcessing = false;
    });

    _generateSummary(text);
  }

  Future<void> _generateSummary(String text) async {
    String apiKey = dotenv.env['GEMINI_API_KEY'] ?? 'your_api_key_here';
    String prompt = 'Summarize the following text extracted from a PDF document, including key points, main ideas, and any important details.';

    var payload = {
      'contents': [{
        'parts': [
          {'text': '$prompt\n\n$text'}
        ]
      }]
    };

    try {
      var response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        var result = jsonDecode(response.body);
        String summary = result['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? 'Summary failed.';
        setState(() {
          _summary = summary;
        });
      } else {
        setState(() {
          _summary = 'Error generating summary.';
        });
      }
    } catch (e) {
      setState(() {
        _summary = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analyze PDF'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _pickPdf,
              child: const Text('Upload PDF'),
            ),
            const SizedBox(height: 16),
            if (_pdfFile != null)
              Text('Selected: ${_pdfFile!.path.split('/').last}'),
            const SizedBox(height: 16),
            if (_isProcessing)
              const Center(child: CircularProgressIndicator()),
            const Text('Extracted Text:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              flex: 1,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SingleChildScrollView(
                    child: Text(_extractedText.isEmpty ? 'Extracted text will be shown here.' : _extractedText),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Summary:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              flex: 1,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SingleChildScrollView(
                    child: Text(_summary.isEmpty ? 'Summary will be shown here.' : _summary),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
