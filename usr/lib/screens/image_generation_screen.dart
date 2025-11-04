import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ImageGenerationScreen extends StatefulWidget {
  const ImageGenerationScreen({super.key});

  @override
  State<ImageGenerationScreen> createState() => _ImageGenerationScreenState();
}

class _ImageGenerationScreenState extends State<ImageGenerationScreen> {
  final TextEditingController _promptController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _referenceImage;
  bool _isGenerating = false;
  String _generatedImageUrl = '';
  bool _isVideo = false;

  Future<void> _pickReferenceImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _referenceImage = image;
      });
    }
  }

  Future<void> _generateContent() async {
    if (_promptController.text.isEmpty) return;

    setState(() {
      _isGenerating = true;
    });

    // Mock API - In production, integrate with image/video generation API
    // For now, simulate generation
    await Future.delayed(const Duration(seconds: 3));

    // Placeholder: In real implementation, call API like DALL-E or similar
    setState(() {
      _generatedImageUrl = 'https://via.placeholder.com/400'; // Replace with actual URL
      _isGenerating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image & Video Generation'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _promptController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Enter a prompt',
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Type: '),
                Radio<bool>(
                  value: false,
                  groupValue: _isVideo,
                  onChanged: (value) => setState(() => _isVideo = value!),
                ),
                const Text('Image'),
                Radio<bool>(
                  value: true,
                  groupValue: _isVideo,
                  onChanged: (value) => setState(() => _isVideo = value!),
                ),
                const Text('Video'),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _pickReferenceImage,
              child: const Text('Pick Reference Image (Optional)'),
            ),
            const SizedBox(height: 16),
            if (_referenceImage != null)
              Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.file(File(_referenceImage!.path), fit: BoxFit.cover),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isGenerating ? null : _generateContent,
              child: _isGenerating ? const CircularProgressIndicator() : const Text('Generate'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: _generatedImageUrl.isNotEmpty
                      ? _isVideo
                          ? const Text('Video generated (placeholder)')
                          : Image.network(_generatedImageUrl)
                      : const Text('Generated content will appear here'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
