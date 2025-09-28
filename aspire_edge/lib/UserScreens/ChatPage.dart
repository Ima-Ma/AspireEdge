import 'dart:convert';
import 'package:aspire_edge/UserScreens/UserComponents/appbar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class ChatPage extends StatefulWidget {
  static const routeName = '/chat';
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _chatHistory = [];

  // GetStarted theme colors
  final Color primaryColor = const Color(0xFF6C95DA); // main color
  final Color hoverColor = const Color(0xFF557FC1); // accent / hover
  final Color backgroundColor = const Color(0xFFf2f2f2); // light background

  @override
  void initState() {
    super.initState();
    // Default greeting
    _chatHistory.add({
      "time": DateTime.now(),
      "message": "👋 Ask me anything!",
      "isSender": false,
    });
  }

  Future<void> getAnswer() async {
    const String apiKey = 'AIzaSyBqIa-mOV0KoW-Bc4PBIVPkuUyNyKKDbCQ';
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey');

    final headers = {'Content-Type': 'application/json'};

    String userMessage = '';
    for (int i = _chatHistory.length - 1; i >= 0; i--) {
      if (_chatHistory[i]["isSender"] == true) {
        userMessage = _chatHistory[i]["message"];
        break;
      }
    }

    final body = jsonEncode({
      "contents": [
        {"parts": [{"text": userMessage}]}
      ]
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      final result = json.decode(response.body);

      final candidates = result["candidates"];
      if (candidates != null &&
          candidates.isNotEmpty &&
          candidates[0]["content"] != null &&
          candidates[0]["content"]["parts"] != null &&
          candidates[0]["content"]["parts"].isNotEmpty) {
        final String reply =
            candidates[0]["content"]["parts"][0]["text"].toString();

        setState(() {
          _chatHistory.add({
            "time": DateTime.now(),
            "message": reply,
            "isSender": false,
          });
        });
      } else {
        setState(() {
          _chatHistory.add({
            "time": DateTime.now(),
            "message": "❌ Gemini API gave no valid response.",
            "isSender": false,
          });
        });
      }
    } catch (e) {
      setState(() {
        _chatHistory.add({
          "time": DateTime.now(),
          "message": "❌ Error: ${e.toString()}",
          "isSender": false,
        });
      });
    }

    // Scroll to bottom after response
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AspireAppBar(),
      body: Stack(
        children: [
          // Chat Messages List
          Container(
            margin: const EdgeInsets.only(bottom: 80, top: 100),
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _chatHistory.length,
              padding: const EdgeInsets.symmetric(vertical: 10),
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final message = _chatHistory[index];
                final isSender = message["isSender"];
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  alignment:
                      isSender ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 300),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSender ? hoverColor : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: const Offset(1, 2),
                        )
                      ],
                    ),
                    child: Text(
                      message["message"],
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        color: isSender ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Chat Input Field
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: hoverColor.withOpacity(0.9),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  )
                ],
              ),
              child: Row(
                children: [
                  // TextField
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white38),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: TextField(
                          controller: _chatController,
                          style: GoogleFonts.inter(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: "Type something...",
                            hintStyle: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Send Button
                  GestureDetector(
                    onTap: () {
                      if (_chatController.text.isNotEmpty) {
                        setState(() {
                          _chatHistory.add({
                            "time": DateTime.now(),
                            "message": _chatController.text,
                            "isSender": true,
                          });
                          _chatController.clear();
                        });
                        getAnswer();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [primaryColor, hoverColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
