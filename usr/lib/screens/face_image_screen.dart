import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:couldai_user_app/providers/wallet_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FaceImageScreen extends StatefulWidget {
  const FaceImageScreen({super.key});

  @override
  State<FaceImageScreen> createState() => _FaceImageScreenState();
}

class _FaceImageScreenState extends State<FaceImageScreen> {
  final TextEditingController _promptController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _faceImage;
  bool _isGenerating = false;
  String _generatedImageUrl = '';

  Future<void> _pickFaceImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _faceImage = image;
      });
    }
  }

  Future<void> _generateImage() async {
    if (_faceImage == null || _promptController.text.isEmpty) return;

    setState(() {
      _isGenerating = true;
    });

    // Mock API - In production, integrate with face image generation API
    await Future.delayed(const Duration(seconds: 3));

    setState(() {
      _generatedImageUrl = 'https://via.placeholder.com/400'; // Replace with actual URL
      _isGenerating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Image with Face'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _pickFaceImage,
              child: const Text('Upload Face Photo'),
            ),
            const SizedBox(height: 16),
            if (_faceImage != null)
              Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.file(File(_faceImage!.path), fit: BoxFit.cover),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _promptController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Enter a prompt',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isGenerating ? null : _generateImage,
              child: _isGenerating ? const CircularProgressIndicator() : const Text('Generate Image'),
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
                      ? Image.network(_generatedImageUrl)
                      : const Text('Generated image will appear here'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
