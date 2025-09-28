import 'package:aspire_edge/UserScreens/CVTips.dart';
import 'package:aspire_edge/UserScreens/FeedBack.dart';
import 'package:aspire_edge/UserScreens/InterviewGuide.dart';
import 'package:aspire_edge/UserScreens/Quiz.dart';
import 'package:aspire_edge/UserScreens/TestimonialPage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Dummy Screens (replace with your actual screens)


class AspireBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AspireBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  Future<bool> _isLoggedIn() async {
    // Option 1: Firebase Auth check
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) return true;

    // Option 2: SharedPreferences fallback check
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool("isLoggedin") ?? false;
  }

  void _showLoginWarning(BuildContext context, String pageName) {
    Flushbar(
      message: "Please login first to access $pageName",
      duration: const Duration(seconds: 3),
      flushbarPosition: FlushbarPosition.TOP,
      margin: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(16),
      backgroundColor: Colors.red.shade600,
      icon: const Icon(Icons.lock, color: Colors.white, size: 28),
    ).show(context);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) async {
          if (index == 0) {
            // Home Page
            bool loggedIn = await _isLoggedIn();
            if (loggedIn) {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(builder: (context) => const HomePage()),
              // );
            } else {
              _showLoginWarning(context, "Home");
            }
          } else if (index == 1) {
            // Courses Page
            bool loggedIn = await _isLoggedIn();
            if (loggedIn) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CVTips()),
              );
            } else {
              _showLoginWarning(context, "CVTips");
            }
          } else if (index == 2) {
            // Explore Page
            bool loggedIn = await _isLoggedIn();
            if (loggedIn) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FeedBack()),
              );
            } else {
              _showLoginWarning(context, "FeedBack");
            }
          } else if (index == 4) {
            // Explore Page
            bool loggedIn = await _isLoggedIn();
            if (loggedIn) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TestimonialPage()),
              );
            } else {
              _showLoginWarning(context, "TestimonialPage");
            }
          }
           else if (index == 5) {
            // Explore Page
            bool loggedIn = await _isLoggedIn();
            if (loggedIn) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const InterviewGuide()),
              );
            } else {
              _showLoginWarning(context, "InterviewGuide");
            }
          }
          else if (index == 3) {
            // Quiz Page
            bool loggedIn = await _isLoggedIn();
            if (loggedIn) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Quiz()),
              );
            } else {
              _showLoginWarning(context, "Quiz");
            }
            
          } else {
            onTap(index);
          }
        },
        backgroundColor: const Color(0xFF6C95DA),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: "Cv Tips"),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: "FeedBack"),
          BottomNavigationBarItem(icon: Icon(Icons.quiz), label: "Quiz"),
          BottomNavigationBarItem(icon: Icon(Icons.feed), label: "Testimonial"),
          BottomNavigationBarItem(icon: Icon(Icons.book_online_sharp), label: "InterviewGuide"),


        ],
      ),
    );
  }
}
