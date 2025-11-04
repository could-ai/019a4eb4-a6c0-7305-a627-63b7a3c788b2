import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:couldai_user_app/providers/wallet_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PhotoAnalyzeScreen extends StatefulWidget {
  const PhotoAnalyzeScreen({super.key});

  @override
  State<PhotoAnalyzeScreen> createState() => _PhotoAnalyzeScreenState();
}

class _PhotoAnalyzeScreenState extends State<PhotoAnalyzeScreen> {
  final ImagePicker _picker = ImagePicker();
  List<XFile> _images = [];
  bool _isAnalyzing = false;
  String _analysisResult = '';

  Future<void> _pickImages() async {
    final List<XFile>? images = await _picker.pickMultiImage();
    if (images != null) {
      setState(() {
        _images = images;
      });
    }
  }

  Future<void> _analyzeImages() async {
    if (_images.isEmpty) return;

    setState(() {
      _isAnalyzing = true;
    });

    // Mock API key - in production, use dotenv
    String apiKey = dotenv.env['GEMINI_API_KEY'] ?? 'your_api_key_here';
    String prompt = 'Analyze these images in detail, including any text, objects, scenes, and provide comprehensive insights.';

    List<Map<String, dynamic>> parts = [{'text': prompt}];
    for (var image in _images) {
      List<int> imageBytes = await image.readAsBytes();
      String base64Image = base64Encode(imageBytes);
      parts.add({
        'inlineData': {
          'mimeType': 'image/jpeg',
          'data': base64Image,
        }
      });
    }

    var payload = {
      'contents': [{'parts': parts}]
    };

    try {
      var response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        var result = jsonDecode(response.body);
        String analysis = result['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? 'Analysis failed.';
        setState(() {
          _analysisResult = analysis;
        });
        // Add points for analysis
        Provider.of<WalletProvider>(context, listen: false).addPoints(2.0);
      } else {
        setState(() {
          _analysisResult = 'Error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _analysisResult = 'Error: $e';
      });
    }

    setState(() {
      _isAnalyzing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analyze Photos'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _pickImages,
              child: const Text('Upload Multiple Photos'),
            ),
            const SizedBox(height: 16),
            if (_images.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Image.file(File(_images[index].path), fit: BoxFit.cover),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isAnalyzing ? null : _analyzeImages,
              child: _isAnalyzing ? const CircularProgressIndicator() : const Text('Analyze'),
            ),
            const SizedBox(height: 16),
            const Text('Analysis:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SingleChildScrollView(
                    child: Text(_analysisResult.isEmpty ? 'Analysis results will be shown here.' : _analysisResult),
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
