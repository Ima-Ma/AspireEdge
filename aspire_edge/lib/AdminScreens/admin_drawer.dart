import 'package:flutter/material.dart';


class AdminDrawer extends StatelessWidget {
  final String adminName; // Admin ka naam dikhane ke liye

  const AdminDrawer({super.key, required this.adminName});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.blue.shade800,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // 👤 Header
            UserAccountsDrawerHeader(
              accountName: Text(
                adminName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              accountEmail: const Text("Administrator"),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.admin_panel_settings, size: 35, color: Colors.blue),
              ),
              decoration: BoxDecoration(color: Colors.blue.shade700),
            ),

            // Career Bank
            ListTile(
              leading: const Icon(Icons.work, color: Colors.white),
              title: const Text("Career Bank", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pushNamed(context, '/admin-careers');
              },
            ),

            // Quizzes
            ListTile(
              leading: const Icon(Icons.quiz, color: Colors.white),
              title: const Text("Quizzes", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pushNamed(context, '/admin-quizzes');
              },
            ),

            // Resources Hub
            ListTile(
              leading: const Icon(Icons.library_books, color: Colors.white),
              title: const Text("Resources Hub", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pushNamed(context, '/admin-resources');
              },
            ),

            // Testimonials
            // ListTile(
            //   leading: const Icon(Icons.people, color: Colors.white),
            //   title: const Text("Testimonials", style: TextStyle(color: Colors.white)),
            //   onTap: () {
            //     Navigator.pushNamed(context, '/admin-testimonials');
            //   },
            // ),

            // Feedback
            ListTile(
              leading: const Icon(Icons.feedback, color: Colors.white),
              title: const Text("Feedback", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pushNamed(context, '/admin-feedback');
              },
            ),

            // Manage Users
            ListTile(
              leading: const Icon(Icons.group, color: Colors.white),
              title: const Text("Manage Users", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pushNamed(context, '/admin-users');
              },
            ),

            const Divider(color: Colors.white54),

            // Logout
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.white),
              title: const Text("Logout", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}
