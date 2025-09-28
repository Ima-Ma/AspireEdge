import 'dart:async';
import 'dart:convert';
import 'package:aspire_edge/UserScreens/UserComponents/appbar.dart';
import 'package:aspire_edge/UserScreens/UserComponents/bottombar.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class Quiz extends StatefulWidget {
  const Quiz({Key? key}) : super(key: key);

  @override
  _QuizState createState() => _QuizState();
}

class _QuizState extends State<Quiz> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String userName = "";
  String userLevel = "";
  String userSkill = "";

  List<Map<String, dynamic>> questions = [];
  Map<int, String> userAnswers = {};
  bool showSplash = false;
  int currentQuestionIndex = 0;

  Timer? _timer;
  Duration remainingTime = const Duration(minutes: 10); // 10-minute timer

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot doc =
          await _firestore.collection("userprofile").doc(user.uid).get();
      Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
      setState(() {
        userName = data?["UserName"] ?? "";
        userLevel = data?["Level"] ?? "";
        userSkill = data?["Skill"] ?? "";
      });
    }
  }

  List<dynamic> _extractJson(String text) {
    try {
      final start = text.indexOf('[');
      final end = text.lastIndexOf(']');
      if (start != -1 && end != -1) {
        final jsonString = text.substring(start, end + 1);
        return jsonDecode(jsonString);
      }
    } catch (e) {}
    return [];
  }

  void _startTimer() {
    _timer?.cancel();
    remainingTime = const Duration(minutes: 10);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingTime.inSeconds <= 0) {
        timer.cancel();
        _submitQuiz(); // auto-submit after 10 minutes
      } else {
        setState(() {
          remainingTime = remainingTime - const Duration(seconds: 1);
        });
      }
    });
  }

  void _startQuizWithSplash() async {
    setState(() => showSplash = true);
    await _generateQuestions();
    await Future.delayed(const Duration(seconds: 2)); // Splash duration
    setState(() => showSplash = false);
    _startTimer(); // start 10-minute timer
  }

  Future<void> _generateQuestions() async {
    questions.clear();
    userAnswers.clear();
    currentQuestionIndex = 0;

const String apiKey = 'AIzaSyBqIa-mOV0KoW-Bc4PBIVPkuUyNyKKDbCQ'; final url = Uri.parse( 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey');

    final prompt =
        "Generate exactly 10 multiple-choice questions (easy) with 3-4 options and correct answer. "
        "Each question is 2 marks. User skill: '$userSkill', level: '$userLevel'. "
        "Return ONLY a JSON array like: "
        "[{\"question\": \"...\", \"options\": [\"Option1\", \"Option2\", \"Option3\"], \"answer\": \"Option2\"}]";

    final body = jsonEncode({
      "contents": [
        {"parts": [{"text": prompt}]}
      ]
    });

    try {
      final response =
          await http.post(url, headers: {'Content-Type': 'application/json'}, body: body);

      if (response.statusCode != 200) {
        throw Exception("Failed to get AI response: ${response.body}");
      }

      final result = jsonDecode(response.body);
      final candidates = result["candidates"];
      if (candidates != null &&
          candidates.isNotEmpty &&
          candidates[0]["content"] != null &&
          candidates[0]["content"]["parts"] != null &&
          candidates[0]["content"]["parts"].isNotEmpty) {
        final String reply = candidates[0]["content"]["parts"][0]["text"];
        final parsedQuestions = _extractJson(reply);

        if (parsedQuestions.isEmpty) {
          throw Exception("No valid JSON found in AI response");
        }

        setState(() {
          questions = parsedQuestions
              .map((q) => {
                    "question": q["question"],
                    "options": List<String>.from(q["options"]),
                    "answer": q["answer"],
                    "marks": 2,
                  })
              .toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _nextQuestion() {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() => currentQuestionIndex++);
    } else {
      _submitQuiz();
    }
  }

  void _previousQuestion() {
    if (currentQuestionIndex > 0) {
      setState(() => currentQuestionIndex--);
    }
  }

  void _submitQuiz() async {
    _timer?.cancel(); // stop timer
    User? user = _auth.currentUser;
    if (user != null) {
      int totalMarks = questions.length * 2;
      int obtainedMarks = 0;
      List<String> wrongAnswers = [];

      for (int i = 0; i < questions.length; i++) {
        final q = questions[i];
        if (userAnswers[i] != null && userAnswers[i] == q["answer"]) {
          obtainedMarks += 2;
        } else {
          wrongAnswers.add(q["question"]);
        }
      }

      double percentage = (obtainedMarks / totalMarks) * 100;
      bool passed = obtainedMarks >= totalMarks / 2;

      await _firestore.collection("quiz").add({
        "userId": user.uid,
        "userName": userName,
        "userSkill": userSkill,
        "userLevel": userLevel,
        "wrongAnswers": wrongAnswers,
        "totalQuestions": questions.length,
        "totalMarks": totalMarks,
        "obtainedMarks": obtainedMarks,
        "percentage": percentage,
        "timestamp": FieldValue.serverTimestamp(),
      });

showDialog(
  context: context,
  builder: (context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: passed
                ? [const Color(0xFF4CAF50), const Color(0xFF2E7D32)] // Green for pass
                : [const Color(0xFFE53935), const Color(0xFFB71C1C)], // Red for fail
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: FaIcon(
                passed ? FontAwesomeIcons.trophy : FontAwesomeIcons.solidTimesCircle,
                size: 45,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              passed ? "Congratulations! 🎉" : "Better Luck Next Time ❌",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const FaIcon(FontAwesomeIcons.solidCheckCircle,
                    size: 18, color: Colors.white70),
                const SizedBox(width: 6),
                Text(
                  "Score: $obtainedMarks / $totalMarks",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const FaIcon(FontAwesomeIcons.percent,
                    size: 18, color: Colors.white70),
                const SizedBox(width: 6),
                Text(
                  "Percentage: ${percentage.toStringAsFixed(2)}%",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.check_circle, color: Color(0xFF3B70B9)),
              label: const Text(
                "OK",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF3B70B9),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 35, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  },
);

    

      setState(() {
        questions.clear();
        userAnswers.clear();
        currentQuestionIndex = 0;
      });
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AspireAppBar(),
      backgroundColor: Colors.grey.shade100,
      body: Stack(
        children: [
          Column(
            children: [
              // Hero Section
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: double.infinity,
                    height: 220,
                    decoration: BoxDecoration(
                      image: const DecorationImage(
                        image: AssetImage('assets/images/onlinequiz.jpg'),
                        fit: BoxFit.cover,
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(60),
                        bottomRight: Radius.circular(60),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -40,
                    left: 16,
                    right: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueAccent.withOpacity(0.6),
                            blurRadius: 20,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(20.0),
           child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Row(
      children: [
        const FaIcon(FontAwesomeIcons.userTie,
            color: Colors.black87, size: 22),
        const SizedBox(width: 8),
        Text(
          "Welcome, $userName",
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    ),
    const SizedBox(height: 8),
    Row(
      children: [
        const FaIcon(FontAwesomeIcons.layerGroup,
            color: Colors.blueGrey, size: 18),
        const SizedBox(width: 6),
        Text(
          "Level: $userLevel",
          style: const TextStyle(fontSize: 16, color: Colors.black87),
        ),
        const SizedBox(width: 16),
        const FaIcon(FontAwesomeIcons.lightbulb,
            color: Colors.orangeAccent, size: 18),
        const SizedBox(width: 6),
        Text(
          "Skill: $userSkill",
          style: const TextStyle(fontSize: 16, color: Colors.black87),
        ),
      ],
    ),
  ],
),

                    ),
                  ),
                ],
              ),
              const SizedBox(height: 60),

              // Start Button
              if (questions.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: ElevatedButton.icon(
                      onPressed: _startQuizWithSplash,
                      icon: const Icon(Icons.play_arrow),
                      label: Text(
                        "Start Quiz",
                        style: GoogleFonts.playfairDisplay(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C95DA),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                  ),
                ),

              // Single Question Card
              if (questions.isNotEmpty)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top Row: Question number + Timer
    // Top Row: Question number + Timer
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text(
      "Question ${currentQuestionIndex + 1} of ${questions.length}",
      style: GoogleFonts.lato(
          fontWeight: FontWeight.bold, fontSize: 16),
    ),
    Row(
      children: [
        const Icon(Icons.timer, color: Colors.red, size: 18),
        const SizedBox(width: 4),
        Text(
          "Remaining Time: ${_formatDuration(remainingTime)}",
          style: GoogleFonts.lato(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.red),
        ),
      ],
    ),
  ],
),

                            const SizedBox(height: 10),
                            Text(
                              questions[currentQuestionIndex]["question"],
                              style: GoogleFonts.lato(
                                  fontSize: 18, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 20),
                            ...questions[currentQuestionIndex]["options"]
                                .map<Widget>((opt) {
                              final isSelected =
                                  userAnswers[currentQuestionIndex] == opt;
                              return ListTile(
                                title: Text(opt),
                                leading: Radio<String>(
                                  value: opt,
                                  groupValue:
                                      userAnswers[currentQuestionIndex],
                                  onChanged: (value) {
                                    setState(() {
                                      userAnswers[currentQuestionIndex] = value!;
                                    });
                                  },
                                ),
                                selected: isSelected,
                              );
                            }).toList(),
                            const Spacer(),
                           Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    if (currentQuestionIndex > 0)
      ElevatedButton(
        onPressed: _previousQuestion,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange.shade700, // readable color
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        child: const Text(
          "Previous",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    ElevatedButton(
      onPressed: userAnswers[currentQuestionIndex] != null
          ? _nextQuestion
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green.shade600, // readable color
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      child: Text(
        currentQuestionIndex == questions.length - 1
            ? "Submit"
            : "Next",
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),
  ],
),

                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Splash Screen
          if (showSplash)
            Container(
              color: const Color(0xFF6C95DA),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(
                    FontAwesomeIcons.graduationCap,
                    size: 70,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 25),
                  Text(
                    "Ready, Set, Quiz! ",
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Get ready to challenge your knowledge.\nAnswer one question at a time!",
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(
                    color: Colors.white,
                  ),
                ],
              ),
            ),
        ],
      ),
       bottomNavigationBar: AspireBottomBar(
    currentIndex: 3, // Quiz tab ka index
    onTap: (index) {
      // Handle navigation (agar alag behaviour chahiye to custom logic likh lo)
      if (index != 3) {
        Navigator.pop(context);
      }
    },
  ),

    );
  }
}
