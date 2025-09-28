import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class AspireAppBar extends StatefulWidget implements PreferredSizeWidget {
  const AspireAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(80); // Height bari

  @override
  State<AspireAppBar> createState() => _AspireAppBarState();
}

class _AspireAppBarState extends State<AspireAppBar> {
  bool isLoggedIn = false;
  Timer? dialogTimer;
  bool firstDialog = true;
  bool isOnAuthPage = false;

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  @override
  void dispose() {
    dialogTimer?.cancel();
    super.dispose();
  }

  Future<void> checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? loggedIn = prefs.getBool('isLoggedin');
    setState(() {
      isLoggedIn = loggedIn ?? false;
    });

    if (!isLoggedIn) {
      startDialogLoop();
    }
  }

  void startDialogLoop() {
    Duration interval = const Duration(seconds: 10);
    dialogTimer = Timer.periodic(interval, (timer) {
      if (isLoggedIn || isOnAuthPage) {
        timer.cancel();
      } else {
        showLoginReminderDialog();
        if (firstDialog) {
          firstDialog = false;
          timer.cancel();
          dialogTimer = Timer.periodic(const Duration(seconds: 20), (_) {
            if (!isLoggedIn && !isOnAuthPage) showLoginReminderDialog();
          });
        }
      }
    });
  }

  void showLoginReminderDialog() {
    if (!mounted) return;
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "Login Reminder",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  spreadRadius: 1,
                )
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline,
                      size: 40, color: Color(0xFF6C95DA)),
                  const SizedBox(height: 12),
                  Text(
                    "Login Required",
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF6C95DA),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "You cannot use this feature without logging in.\n"
                    "Please login or signup to continue.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C95DA),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {
                            isOnAuthPage = true;
                          });
                          Navigator.pushNamed(context, '/GetStarted').then((_) {
                            setState(() {
                              isOnAuthPage = false;
                            });
                          });
                        },
                        icon: const Icon(Icons.person_add,
                            size: 18, color: Colors.white),
                        label: Text(
                          "Signup",
                          style: GoogleFonts.playfairDisplay(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C95DA),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {
                            isOnAuthPage = true;
                          });
                          Navigator.pushNamed(context, '/Login').then((_) {
                            setState(() {
                              isOnAuthPage = false;
                            });
                          });
                        },
                        icon: const Icon(Icons.login,
                            size: 18, color: Colors.white),
                        label: Text(
                          "Login",
                          style: GoogleFonts.playfairDisplay(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (_, anim, __, child) {
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(scale: anim, child: child),
        );
      },
    );
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    setState(() {
      isLoggedIn = false;
    });
    startDialogLoop();
    Navigator.pushReplacementNamed(context, '/Login');
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false, // Back arrow hata diya
      backgroundColor: const Color(0xFF6C95DA),
      elevation: 0,
      toolbarHeight: 80, // Height barhayi
      title: Row(
        children: [
          SizedBox(
            height: 135, // Logo height
            width: 135,  // Logo width
            child: Image.asset(
              'assets/images/logocarrer.png',
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
      centerTitle: false, // Left aligned logo
      actions: [
        if (isLoggedIn) ...[
          IconButton(
            tooltip: "Profile",
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/UserProfile'),
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
                    icon: const Icon(Icons.notifications, color: Colors.white),
                    onPressed: () => Navigator.pushNamed(context, '/Notifi'),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: CircleAvatar(
                        radius: 8,
                        backgroundColor: Colors.red,
                        child: Text(
                          unreadCount.toString(),
                          style: const TextStyle(
                            fontSize: 10,
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
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: logout,
          ),
        ] else
          PopupMenuButton<String>(
            tooltip: "Account",
            icon: const Icon(Icons.account_circle, color: Colors.white),
            onSelected: (value) {
              if (value == 'Signup') {
                setState(() {
                  isOnAuthPage = true;
                });
                Navigator.pushNamed(context, '/GetStarted').then((_) {
                  setState(() {
                    isOnAuthPage = false;
                  });
                });
              } else if (value == 'Login') {
                setState(() {
                  isOnAuthPage = true;
                });
                Navigator.pushNamed(context, '/Login').then((_) {
                  setState(() {
                    isOnAuthPage = false;
                  });
                });
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'Signup',
                child: Row(
                  children: [
                    Icon(Icons.person_add, size: 18),
                    SizedBox(width: 8),
                    Text('Signup'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'Login',
                child: Row(
                  children: [
                    Icon(Icons.login, size: 18),
                    SizedBox(width: 8),
                    Text('Login'),
                  ],
                ),
              ),
            ],
          ),
        const SizedBox(width: 10),
      ],
    );
  }
}
