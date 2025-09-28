import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyAppBar extends StatefulWidget implements PreferredSizeWidget {
  const MyAppBar({Key? key}) : super(key: key);

  @override
  _MyAppBarState createState() => _MyAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _MyAppBarState extends State<MyAppBar> {
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? loggedIn = prefs.getBool('isLoggedin');
    setState(() {
      isLoggedIn = loggedIn ?? false;
    });
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    setState(() {
      isLoggedIn = false;
    });

    Navigator.pushReplacementNamed(context, '/Login');
  }

@override
Widget build(BuildContext context) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(kToolbarHeight),
    child: Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),   // left bottom curve
          bottomRight: Radius.circular(20),  // right bottom curve
          // topLeft: Radius.circular(20),      // left top curve
          // topRight: Radius.circular(20),     // right top curve
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: AppBar(
        title: const Text(
          "My Home",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent, // transparent so container bg visible
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          if (isLoggedIn) ...[
            IconButton(
              tooltip: "Profile",
              icon: const Icon(Icons.person),
              onPressed: () {
                Navigator.pushNamed(context, '/UserProfile');
              },
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Notifications')
                  .where('isRead', isEqualTo: false)
                  .snapshots(),
              builder: (context, snapshot) {
                int unreadCount = snapshot.data?.docs.length ?? 0;
                return Stack(
                  children: [
                    IconButton(
                      tooltip: "Notifications",
                      icon: const Icon(Icons.notifications),
                      onPressed: () {
                        Navigator.pushNamed(context, '/PushNotification');
                      },
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            IconButton(
              tooltip: "Logout",
              icon: const Icon(Icons.logout),
              onPressed: logout,
            ),
                IconButton(
      tooltip: "Quiz",
      icon: const Icon(Icons.quiz), // Quiz icon
      onPressed: () {
        Navigator.pushNamed(context, '/Quiz'); // Quiz page route
      },
    ),

          ] else
            PopupMenuButton<String>(
              tooltip: "Account",
              icon: const Icon(Icons.account_circle),
              onSelected: (value) {
                if (value == 'Signup') {
                  Navigator.pushNamed(context, '/Signup');
                } else if (value == 'Login') {
                  Navigator.pushNamed(context, '/Login');
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem<String>(
                  value: 'Signup',
                  child: Text('Signup'),
                ),
                const PopupMenuItem<String>(
                  value: 'Login',
                  child: Text('Login'),
                ),
              ],
            ),
          const SizedBox(width: 10),
        ],
      ),
    ),
  );
}
}