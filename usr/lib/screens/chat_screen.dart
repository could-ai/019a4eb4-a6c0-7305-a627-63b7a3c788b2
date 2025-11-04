import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _attachedImage;
  List<Map<String, String>> _messages = [
    {'sender': 'ai', 'message': 'Hello! I\'m Bish. Ask me anything or upload an image to analyze.'}
  ];
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _attachedImage = image;
      });
    }
  }

  Future<void> _sendMessage() async {
    String text = _messageController.text.trim();
    if (text.isEmpty && _attachedImage == null) return;

    setState(() {
      _messages.add({'sender': 'user', 'message': text.isNotEmpty ? text : '[Image Attached]'});
      _isLoading = true;
    });

    String apiKey = dotenv.env['GEMINI_API_KEY'] ?? 'your_api_key_here';
    List<Map<String, dynamic>> parts = [];
    if (text.isNotEmpty) parts.add({'text': text});
    if (_attachedImage != null) {
      List<int> imageBytes = await _attachedImage!.readAsBytes();
      String base64Image = base64Encode(imageBytes);
      parts.add({
        'inlineData': {
          'mimeType': 'image/jpeg',
          'data': base64Image,
        }
      });
    }

    var payload = {'contents': [{'parts': parts}]};

    try {
      var response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        var result = jsonDecode(response.body);
        String aiMessage = result['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? 'Sorry, I couldn\'t respond.';
        setState(() {
          _messages.add({'sender': 'ai', 'message': aiMessage});
        });
      } else {
        setState(() {
          _messages.add({'sender': 'ai', 'message': 'Error: Unable to get response.'});
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({'sender': 'ai', 'message': 'Error: $e'});
      });
    }

    setState(() {
      _messageController.clear();
      _attachedImage = null;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ask Questions'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                var message = _messages[index];
                bool isUser = message['sender'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue[600] : Colors.grey[700],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      message['message']!,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_attachedImage != null)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey[800],
              child: Row(
                children: [
                  Image.file(File(_attachedImage!.path), width: 50, height: 50, fit: BoxFit.cover),
                  const SizedBox(width: 8),
                  const Text('Image attached'),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _attachedImage = null),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: _pickImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: _isLoading ? const CircularProgressIndicator() : const Icon(Icons.send),
                  onPressed: _isLoading ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
