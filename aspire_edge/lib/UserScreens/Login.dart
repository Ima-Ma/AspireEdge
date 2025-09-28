import 'package:another_flushbar/flushbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isHovering = false;
  bool _loading = false;
  bool _obscurePassword = true; 

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _loading = true);

      try {
        UserCredential userCredential =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection("users")
            .doc(userCredential.user!.uid)
            .get();

        String role = "User";
        String userName = "User";
        if (userDoc.exists && userDoc.data() != null) {
          role = (userDoc.get("Role") ?? "User");
          userName = (userDoc.get("UserName") ?? "User");
        }

        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setBool("isLoggedin", true);
        prefs.setString("userEmail", userCredential.user!.email ?? "");
        prefs.setString("userName", userName); 

        if (!mounted) return;
        Flushbar(
          duration: const Duration(seconds: 3),
          flushbarPosition: FlushbarPosition.TOP,
          margin: const EdgeInsets.all(12),
          borderRadius: BorderRadius.circular(16),
          backgroundColor: Colors.green.shade600,
          icon: const Icon(Icons.check_circle, color: Colors.white, size: 28),
          title: "Welcome Back",
          titleColor: Colors.white,
          message: "$userName logged in successfully!",
          messageColor: Colors.white,
          shouldIconPulse: true,
        ).show(context);

        Future.delayed(const Duration(seconds: 2), () {
          if (role == "Admin") {
            Navigator.pushReplacementNamed(context, '/Admin');
          } else {
            Navigator.pushReplacementNamed(context, '/HomePage');
          }
        });
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        Flushbar(
          duration: const Duration(seconds: 3),
          flushbarPosition: FlushbarPosition.TOP,
          margin: const EdgeInsets.all(12),
          borderRadius: BorderRadius.circular(16),
          backgroundColor: Colors.red.shade600,
          icon: const Icon(Icons.error, color: Colors.white, size: 28),
          title: "Login Failed",
          titleColor: Colors.white,
          message: e.message ?? "An error occurred",
          messageColor: Colors.white,
          shouldIconPulse: true,
        ).show(context);
      } finally {
        setState(() => _loading = false);
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

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .set({
        'UserName': user.displayName,
        'Email': email,
        'Role': role,
      }, SetOptions(merge: true));

      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setBool('isLoggedin', true);
      prefs.setString('userEmail', email!);
      prefs.setString('userName', user.displayName ?? "User"); 

      if (!mounted) return;
      Flushbar(
        message: "Google Sign-In successful as $role!",
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.green,
        flushbarPosition: FlushbarPosition.TOP,
      ).show(context);

      Future.delayed(const Duration(seconds: 2), () {
        if (role == 'Admin') {
          Navigator.pushReplacementNamed(context, '/Admin');
        } else {
          Navigator.pushReplacementNamed(context, '/mainhome');
        }
      });
    } catch (e) {
      if (!mounted) return;
      Flushbar(
        message: "Google Sign-In failed: ${e.toString()}",
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.red,
        flushbarPosition: FlushbarPosition.TOP,
      ).show(context);
    }
  }

  Future<void> _forgotPassword() async {
    if (_emailController.text.trim().isEmpty) {
      Flushbar(
        duration: const Duration(seconds: 3),
        flushbarPosition: FlushbarPosition.TOP,
        margin: const EdgeInsets.all(12),
        borderRadius: BorderRadius.circular(16),
        backgroundColor: Colors.orange.shade600,
        icon: const Icon(Icons.info_outline, color: Colors.white, size: 28),
        title: "Reset Password",
        titleColor: Colors.white,
        message: "Please enter your email to reset password",
        messageColor: Colors.white,
        shouldIconPulse: true,
      ).show(context);
      return;
    }

    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: _emailController.text.trim());

      Flushbar(
        duration: const Duration(seconds: 3),
        flushbarPosition: FlushbarPosition.TOP,
        margin: const EdgeInsets.all(12),
        borderRadius: BorderRadius.circular(16),
        backgroundColor: Colors.green.shade600,
        icon: const Icon(Icons.email, color: Colors.white, size: 28),
        title: "Email Sent",
        titleColor: Colors.white,
        message: "Password reset email sent! Check your inbox.",
        messageColor: Colors.white,
        shouldIconPulse: true,
      ).show(context);
    } on FirebaseAuthException catch (e) {
      Flushbar(
        duration: const Duration(seconds: 3),
        flushbarPosition: FlushbarPosition.TOP,
        margin: const EdgeInsets.all(12),
        borderRadius: BorderRadius.circular(16),
        backgroundColor: Colors.red.shade600,
        icon: const Icon(Icons.error, color: Colors.white, size: 28),
        title: "Error",
        titleColor: Colors.white,
        message: e.message ?? "Failed to send reset email",
        messageColor: Colors.white,
        shouldIconPulse: true,
      ).show(context);
    }
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

           
            Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      const SizedBox(height: 60),
                   
                      Text(
                        "Welcome Back",
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
                      const SizedBox(height: 20),
                    
                      Image.asset(
                        'assets/images/GetStart.png',
                        height: 200,
                      ),
                      const SizedBox(height: 22),

                   
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                        
                            TextFormField(
                              controller: _emailController,
                              style: const TextStyle(color: Colors.black87),
                              decoration: InputDecoration(
                                hintText: "Email",
                                hintStyle: TextStyle(
                                    color: Colors.grey.shade600, fontSize: 16),
                                filled: true,
                                fillColor: Colors.grey.shade200,
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 20),
                                prefixIcon: const Icon(Icons.email,
                                    color: Color(0xFF6C95DA)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (value) =>
                                  value == null || value.isEmpty
                                      ? "Enter email"
                                      : null,
                            ),
                            const SizedBox(height: 12),

                           
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: const TextStyle(color: Colors.black87),
                              decoration: InputDecoration(
                                hintText: "Password",
                                hintStyle: TextStyle(
                                    color: Colors.grey.shade600, fontSize: 16),
                                filled: true,
                                fillColor: Colors.grey.shade200,
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 16, horizontal: 20),
                                prefixIcon: const Icon(Icons.lock,
                                    color: Color(0xFF6C95DA)),
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
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (value) =>
                                  value == null || value.isEmpty
                                      ? "Enter password"
                                      : null,
                            ),
                            const SizedBox(height: 12),

                            // Forgot Password
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: _forgotPassword,
                                child: const Text(
                                  "Forgot Password?",
                                  style: TextStyle(
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Login Button
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
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    backgroundColor: _isHovering
                                        ? const Color(0xFF6C95DA)
                                        : Colors.transparent,
                                  ),
                                  onPressed: _loading ? null : _login,
                                  child: _loading
                                      ? const CircularProgressIndicator(
                                          color: Colors.white,
                                        )
                                      : Text(
                                          "Login",
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
                                  icon: const FaIcon(FontAwesomeIcons.facebook),
                                  color: const Color(0xFF1877F2),
                                  onPressed: () {
                                    Flushbar(
                                      message:
                                          "Facebook Login not implemented yet",
                                      duration: const Duration(seconds: 2),
                                      backgroundColor: Colors.orange,
                                      flushbarPosition: FlushbarPosition.TOP,
                                    ).show(context);
                                  },
                                ),
                                IconButton(
                                  icon: const FaIcon(FontAwesomeIcons.twitter),
                                  color: const Color(0xFF1DA1F2),
                                  onPressed: () {
                                    Flushbar(
                                      message:
                                          "Twitter Login not implemented yet",
                                      duration: const Duration(seconds: 2),
                                      backgroundColor: Colors.blueAccent,
                                      flushbarPosition: FlushbarPosition.TOP,
                                    ).show(context);
                                  },
                                ),
                                IconButton(
                                  icon: const FaIcon(FontAwesomeIcons.google),
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

                            const SizedBox(height: 60),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom bar
            Align(
              alignment: Alignment.bottomCenter,
              child: ClipRRect(
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
                        "Don't have an account? ",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      GestureDetector(
                        onTap: () =>
                            Navigator.pushNamed(context, '/SignUp'),
                        child: const Text(
                          "Sign Up",
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
            ),
          ],
        ),
      ),
    );
  }
}
