import 'package:flutter/material.dart';

// 📌 Bottom Navigation Bar with individual routes
class CustomBottomBar extends StatelessWidget {
  final int currentIndex;

  const CustomBottomBar({
    super.key,
    required this.currentIndex,
  });

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/Admin');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/admin-careers');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/admin-quizzes');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/admin-resources');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF6C95DA),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => _onItemTapped(context, index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.work), label: "Admin Careers"),
          BottomNavigationBarItem(icon: Icon(Icons.quiz), label: "Admin Quizzes"),
          BottomNavigationBarItem(icon: Icon(Icons.library_books), label: "Admin Resources"),
        ],
      ),
    );
  }
}
