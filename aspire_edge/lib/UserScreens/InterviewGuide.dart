import 'package:aspire_edge/UserScreens/UserComponents/appbar.dart';
import 'package:aspire_edge/UserScreens/UserComponents/bottombar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:web/web.dart' as web; // for browser TTS
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_tts/flutter_tts.dart';

class InterviewGuide extends StatefulWidget {
  const InterviewGuide({Key? key}) : super(key: key);

  @override
  _InterviewGuideState createState() => _InterviewGuideState();
}

class ChatMessage {
  final String text;
  final bool fromUser;
  ChatMessage({required this.text, required this.fromUser});
}

class _InterviewGuideState extends State<InterviewGuide> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final FlutterTts _flutterTts = FlutterTts();

  String userName = "";
  String userLevel = "Student";
  String userSkill = "General";

  bool _loadingUser = true;
  bool _isAiThinking = false;
  List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _topicController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Gemini API key (replace with yours)
  static const String geminiApiKey = "AIzaSyBlQdCsngesteT7E96BKv0ttMg_8m3sLKA";
  late final GenerativeModel _model;

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(model: "gemini-1.5-flash", apiKey: geminiApiKey);
    _loadUserData();
    _messages.add(ChatMessage(
        text:
            '👋 Hey! Enter a topic (e.g., Development, Biology, Ethics) and tap Send or Get Tips.',
        fromUser: false));
  }

  @override
  void dispose() {
    _controller.dispose();
    _topicController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _loadingUser = true);
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        final doc =
            await _firestore.collection('userprofile').doc(user.uid).get();
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
        setState(() {
          userName = data?['UserName'] ?? user.displayName ?? '';
          userLevel = data?['Level'] ?? 'Student';
          userSkill = data?['Skill'] ?? 'General';
        });
      }
    } catch (_) {
      // ignore
    } finally {
      setState(() => _loadingUser = false);
    }
  }

  String _buildSystemPrompt(String mode) {
    return "You are a friendly interview coach for a young audience. "
        "User level: $userLevel, skill: $userSkill. "
        "If mode = 'tips': give 5 practical tips + 5 common questions with short answers. "
        "If mode = 'practice': ask one interview question at a time. "
        "If mode = 'answer': act like interviewer and give feedback on user's reply. "
        "Always be concise, clear, and encouraging.";
  }

  Future<String> _callGemini(String userMessage,
      {String mode = "answer"}) async {
    setState(() => _isAiThinking = true);
    try {
      final systemPrompt = _buildSystemPrompt(mode);
      final fullPrompt = "$systemPrompt\nUser: $userMessage";

      for (int i = 0; i < 3; i++) {
        try {
          final response =
              await _model.generateContent([Content.text(fullPrompt)]);
          return response.text ?? "⚠️ No response received.";
        } catch (e) {
          if (e.toString().contains("503")) {
            await Future.delayed(
                Duration(seconds: 2 * (i + 1))); // wait before retry
            continue;
          }
          rethrow;
        }
      }
      return "⚠️ Gemini servers are overloaded. Please try again later.";
    } catch (e) {
      return "Gemini Error: $e";
    } finally {
      setState(() => _isAiThinking = false);
    }
  }

  Future<void> _speak(String text) async {
    if (kIsWeb) {
      final utterance = web.SpeechSynthesisUtterance(text);
      utterance.lang = "en-US";
      web.window.speechSynthesis.speak(utterance);
    } else {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(0.9);
      await _flutterTts.speak(text);
    }
  }

  void _scrollToBottom({int delayMs = 100}) {
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (_scrollController.hasClients) {
        final pos = _scrollController.position.maxScrollExtent;
        _scrollController.animateTo(
          pos,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // 🔹 Firestore logging
  Future<void> _storeSession({
    required String topic,
    required String mode,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection("InterviewTipsData").add({
        "userId": user.uid,
        "userName": userName,
        "userLevel": userLevel,
        "userSkill": userSkill,
        "topic": topic,
        "mode": mode,
        "startTime": startTime,
        "endTime": endTime,
        "lastPractice": DateTime.now(),
      });
    } catch (e) {
      debugPrint("🔥 Firestore save error: $e");
    }
  }

  // send free-form chat input
  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    setState(() => _messages.add(ChatMessage(text: text, fromUser: true)));
    _scrollToBottom();

    final aiResponse = await _callGemini(text, mode: "answer");
    setState(() => _messages.add(ChatMessage(text: aiResponse, fromUser: false)));
    _scrollToBottom();
  }

  // topic send
  Future<void> _sendTopicAsPrompt() async {
    final topic = _topicController.text.trim();
    if (topic.isEmpty) return;
    final userPrompt = "Give me interview guidance for topic: $topic";

    final start = DateTime.now();

    setState(() {
      _messages.add(ChatMessage(text: userPrompt, fromUser: true));
      _topicController.clear();
    });
    _scrollToBottom();

    final aiResponse = await _callGemini(userPrompt, mode: "tips");
    setState(() => _messages.add(ChatMessage(text: aiResponse, fromUser: false)));
    _scrollToBottom();

    final end = DateTime.now();
    await _storeSession(topic: topic, mode: "tips", startTime: start, endTime: end);
  }

  // Get tips
  void _getTips() async {
    final topic =
        _topicController.text.trim().isEmpty ? userSkill : _topicController.text.trim();
    final prompt = "Give me interview tips and questions for a $userLevel in $topic.";
    final start = DateTime.now();

    setState(() =>
        _messages.add(ChatMessage(text: "✨ Generating personalized tips...", fromUser: true)));
    _scrollToBottom();

    final aiResponse = await _callGemini(prompt, mode: "tips");
    setState(() {
      _messages.removeWhere((m) => m.text.contains("Generating personalized tips") && m.fromUser);
      _messages.add(ChatMessage(text: aiResponse, fromUser: false));
    });
    _scrollToBottom();

    final end = DateTime.now();
    await _storeSession(topic: topic, mode: "tips", startTime: start, endTime: end);
  }

  // Start practice
  void _startPractice() async {
    final topic =
        _topicController.text.trim().isEmpty ? userSkill : _topicController.text.trim();
    final prompt = "Start a mock interview for a $userLevel in $topic. Ask one question.";
    final start = DateTime.now();

    setState(() => _messages.add(ChatMessage(text: "🎤 Starting practice...", fromUser: true)));
    _scrollToBottom();

    final aiResponse = await _callGemini(prompt, mode: "practice");
    setState(() {
      _messages.removeWhere((m) => m.text.contains("Starting practice") && m.fromUser);
      _messages.add(ChatMessage(text: aiResponse, fromUser: false));
    });
    _scrollToBottom();

    final end = DateTime.now();
    await _storeSession(topic: topic, mode: "practice", startTime: start, endTime: end);
  }

  // --- UI Builders ---
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6C95DA), Color(0xFF8E54E9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            child: Text(userName.isNotEmpty ? userName[0].toUpperCase() : "U",
                style: const TextStyle(fontSize: 22, color: Color(0xFF6C95DA))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(userName.isEmpty ? "Future Rockstar 🚀" : "Hi, $userName 👋",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 4),
              Text("$userLevel • $userSkill", style: const TextStyle(color: Colors.white70)),
            ]),
          ),
          IconButton(onPressed: _loadUserData, icon: const Icon(Icons.refresh, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildTopicField() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextField(
        controller: _topicController,
        textInputAction: TextInputAction.send,
        decoration: InputDecoration(
          hintText: "💡 Enter your topic (e.g., Development, Biology, Ethics)...",
          filled: true,
          fillColor: Colors.white,
          prefixIcon: const Icon(Icons.topic, color: Color(0xFF6C95DA)),
          suffixIcon: IconButton(
            icon: const Icon(Icons.send, color: Color(0xFF6C95DA)),
            onPressed: _sendTopicAsPrompt,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
        onSubmitted: (_) => _sendTopicAsPrompt(),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _getTips,
            icon: const Icon(Icons.lightbulb_outlined),
            label: const Text("Get Tips" , style: TextStyle(color: Colors.white),),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C95DA) ,
              iconColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _startPractice,
            icon: const Icon(Icons.mic),
            label: const Text("Practice" , style: TextStyle(color: Colors.white),),
            style: ElevatedButton.styleFrom(
              backgroundColor:const Color(0xFF6C95DA) ,
              iconColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildChatBubble(ChatMessage m) {
    final align = m.fromUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bg = m.fromUser ? const Color(0xFFE6F3FF) : Colors.white;
    final radius = BorderRadius.circular(16);

    return Column(
      crossAxisAlignment: align,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: radius,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: SelectableText(m.text)),
              if (!m.fromUser)
                IconButton(
                  icon: const Icon(Icons.volume_up, color: Color(0xFF6C95DA)),
                  onPressed: () async => await _speak(m.text),
                )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      itemCount: _messages.length,
      itemBuilder: (_, i) => _buildChatBubble(_messages[i]),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: Colors.transparent,
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: "Type your reply...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _isAiThinking
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send, color: Color(0xFF6C95DA)),
                ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AspireAppBar(),
      backgroundColor: const Color(0xFFF6F8FF),
      body: Column(
        children: [
          _buildHeader(),
          _buildTopicField(),
          _buildActionButtons(),
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                  child: Card(
                    elevation: 1.5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(children: const [
                        Icon(Icons.info_outline, color: Color(0xFF6C95DA)),
                        SizedBox(width: 12),
                        Expanded(child: Text("AI-powered interview tips & practice based on your level and chosen topic.")),
                      ]),
                    ),
                  ),
                ),
                Expanded(child: _buildChatList()),
                _buildInputBar(),
              ],
            ),
          ),
        ],
      ),
        bottomNavigationBar: AspireBottomBar(
        currentIndex: 5,
        onTap: (index) {
          if (index != 5) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}
