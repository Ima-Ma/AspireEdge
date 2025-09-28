import 'package:another_flushbar/flushbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SignUp extends StatefulWidget {
  const SignUp({Key? key}) : super(key: key);

  @override
  _SignUpState createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isHovering = false;
  bool _obscurePassword = true; // 👁️ Password show/hide ke liye

  Future<void> _signup() async {
    if (_formKey.currentState!.validate()) {
      try {
        final email = _emailController.text.trim().toLowerCase();
        final role = (email == 'admin@gmail.com') ? 'Admin' : 'User';
        final userName = _usernameController.text.trim();

        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: _passwordController.text.trim(),
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'UserName': userName,
          'Email': email,
          'Password': _passwordController.text.trim(),
          'Role': role,
        });

        _usernameController.clear();
        _emailController.clear();
        _passwordController.clear();

        Flushbar(
          duration: const Duration(seconds: 3),
          flushbarPosition: FlushbarPosition.TOP,
          margin: const EdgeInsets.all(12),
          borderRadius: BorderRadius.circular(16),
          backgroundColor: Colors.green.shade600,
          icon: const Icon(Icons.check_circle, color: Colors.white, size: 28),
          title: "Signup Successful",
          titleColor: Colors.white,
          message: "$userName registered successfully as $role!",
          messageColor: Colors.white,
          shouldIconPulse: true,
        ).show(context);

        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setBool('isLoggedin', true);
        prefs.setString('userEmail', email);

        Future.delayed(const Duration(seconds: 2), () {
          if (role == 'Admin') {
            Navigator.pushReplacementNamed(context, '/Admin');
          } else {
            Navigator.pushReplacementNamed(context, '/mainhome');
          }
        });
      } catch (e) {
        Flushbar(
          duration: const Duration(seconds: 3),
          flushbarPosition: FlushbarPosition.TOP,
          margin: const EdgeInsets.all(12),
          borderRadius: BorderRadius.circular(16),
          backgroundColor: Colors.red.shade600,
          icon: const Icon(Icons.error, color: Colors.white, size: 28),
          title: "Signup Failed",
          titleColor: Colors.white,
          message: e.toString(),
          messageColor: Colors.white,
          shouldIconPulse: true,
        ).show(context);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      GoogleAuthProvider googleProvider = GoogleAuthProvider();

      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithPopup(googleProvider);

      final user = userCredential.user;
      final email = user?.email?.toLowerCase();
      final role = (email == 'admin@gmail.com') ? 'Admin' : 'User';
      final userName = user?.displayName ?? "User";

      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'UserName': userName,
        'Email': email,
        'Role': role,
      }, SetOptions(merge: true));

      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setBool('isLoggedin', true);
      prefs.setString('userEmail', email!);

      if (!mounted) return;
      Flushbar(
        duration: const Duration(seconds: 3),
        flushbarPosition: FlushbarPosition.TOP,
        margin: const EdgeInsets.all(12),
        borderRadius: BorderRadius.circular(16),
        backgroundColor: Colors.green.shade600,
        icon: const Icon(Icons.check_circle, color: Colors.white, size: 28),
        title: "Google Sign-In",
        titleColor: Colors.white,
        message: "$userName signed in successfully as $role!",
        messageColor: Colors.white,
        shouldIconPulse: true,
      ).show(context);

      Future.delayed(const Duration(seconds: 2), () {
        if (role == 'Admin') {
          Navigator.pushReplacementNamed(context, '/AdminIndex');
        } else {
          Navigator.pushReplacementNamed(context, '/mainhome');
        }
      });
    } catch (e) {
      if (!mounted) return;
      Flushbar(
        duration: const Duration(seconds: 3),
        flushbarPosition: FlushbarPosition.TOP,
        margin: const EdgeInsets.all(12),
        borderRadius: BorderRadius.circular(16),
        backgroundColor: Colors.red.shade600,
        icon: const Icon(Icons.error, color: Colors.white, size: 28),
        title: "Google Sign-In Failed",
        titleColor: Colors.white,
        message: e.toString(),
        messageColor: Colors.white,
        shouldIconPulse: true,
      ).show(context);
    }
  }

  InputDecoration _inputDecoration(String hintText, IconData icon,
      {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 16),
      filled: true,
      fillColor: Colors.grey.shade200,
      contentPadding:
          const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      prefixIcon: Icon(icon, color: const Color(0xFF6C95DA)),
      suffixIcon: suffixIcon, // 👈 extra widget support
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SizedBox(
        height: screenHeight,
        child: Stack(
          children: [
        
            Positioned(
              top: 20,
              left: -60,
              child: Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  color: Color(0xFF6C95DA),
                  shape: BoxShape.circle,
                ),
              ),
            ),

         
            Positioned(
              top: 20,
              right: -60,
              child: Container(
                width: 140,
                height: 140,
                decoration: const BoxDecoration(
                  color: Color(0xFF6C95DA),
                  shape: BoxShape.circle,
                ),
              ),
            ),

          
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        children: [
                          const SizedBox(height: 40),
                          // Heading
                          Text(
                            "Create Account",
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF6C95DA),
                            ),
                          ),
                          const SizedBox(height: 6),

                      
                          Container(
                            width: 60,
                            height: 3,
                            color: const Color(0xFF6C95DA),
                          ),
                          const SizedBox(height: 18),

                          // Image
                          Image.asset(
                            'assets/images/GetStart.png',
                            height: 200,
                          ),
                          const SizedBox(height: 22),

                          // Form Fields
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _usernameController,
                                  style: const TextStyle(color: Colors.black87),
                                  decoration: _inputDecoration(
                                      "Full Name", Icons.person),
                                  validator: (value) =>
                                      value == null || value.isEmpty
                                          ? "Enter your name"
                                          : null,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _emailController,
                                  style: const TextStyle(color: Colors.black87),
                                  decoration: _inputDecoration(
                                      "Email", Icons.email),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Enter your email";
                                    }
                                    if (!value.contains("@")) {
                                      return "Enter valid email";
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  style: const TextStyle(color: Colors.black87),
                                  decoration: _inputDecoration(
                                    "Password",
                                    Icons.lock,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: const Color(0xFF6C95DA),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                  ),
                                  validator: (value) =>
                                      value == null || value.length < 6
                                          ? "Password must be at least 6 characters"
                                          : null,
                                ),
                                const SizedBox(height: 20),

                                // SignUp Button
                                SizedBox(
                                  width: double.infinity,
                                  child: MouseRegion(
                                    onEnter: (_) =>
                                        setState(() => _isHovering = true),
                                    onExit: (_) =>
                                        setState(() => _isHovering = false),
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                            color: Color(0xFF6C95DA)),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                        ),
                                        backgroundColor: _isHovering
                                            ? const Color(0xFF6C95DA)
                                            : Colors.transparent,
                                      ),
                                      onPressed: _signup,
                                      child: Text(
                                        "Sign Up",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: _isHovering
                                              ? Colors.white
                                              : const Color(0xFF6C95DA),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),

                                // Social Icons
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 1,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    IconButton(
                                      icon: const FaIcon(
                                          FontAwesomeIcons.facebook),
                                      color: const Color(0xFF1877F2),
                                      onPressed: () {},
                                    ),
                                    IconButton(
                                      icon: const FaIcon(
                                          FontAwesomeIcons.twitter),
                                      color: const Color(0xFF1DA1F2),
                                      onPressed: () {},
                                    ),
                                    IconButton(
                                      icon: const FaIcon(
                                          FontAwesomeIcons.google),
                                      color: const Color(0xFFDB4437),
                                      onPressed: _signInWithGoogle,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Container(
                                        height: 1,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Bottom bar
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(40),
                  ),
                  child: Container(
                    width: double.infinity,
                    color: const Color(0xFF6C95DA),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Already have an account? ",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/Login'),
                          child: const Text(
                            "Login",
                            style: TextStyle(
                              color: Colors.yellowAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
