import 'package:aspire_edge/UserScreens/Login.dart';
import 'package:aspire_edge/UserScreens/SignUp.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: GetStarted(),
  ));
}

class GetStarted extends StatefulWidget {
  const GetStarted({Key? key}) : super(key: key);

  @override
  _GetStartedState createState() => _GetStartedState();
}

class _GetStartedState extends State<GetStarted> {
  bool _isHoveringStart = false;
  bool _isHoveringLogin = false;

  // Slide Transition Route
  Route _createRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0); // Right to left
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
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
            // 🔹 Decorative Top Circles
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

            /// 🔹 Top Wave
            ClipPath(
              clipper: WaveClipperTop(),
              child: Container(
                height: 250,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6C95DA), Color(0xFF557FC1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),

            SafeArea(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: screenHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 🔹 Top Image / Logo
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Image.asset(
                              'assets/images/carrers.png',
                              fit: BoxFit.contain,
                              height: 250,
                            ),
                          ),
                        ),

                        // 🔹 Text Section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              Text(
                                "Aspire Edge",
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF6C95DA),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: 70,
                                height: 3,
                                color: const Color(0xFF6C95DA),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Your Gateway to Growth, Opportunities, "
                                "and a Brighter Future with Espire Edge",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.lato(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(FontAwesomeIcons.graduationCap,
                                      color: Color(0xFF6C95DA), size: 24),
                                  SizedBox(width: 15),
                                  Icon(FontAwesomeIcons.briefcase,
                                      color: Color(0xFF6C95DA), size: 24),
                                  SizedBox(width: 15),
                                  Icon(FontAwesomeIcons.userTie,
                                      color: Color(0xFF6C95DA), size: 24),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const Spacer(), // Flexible space between content and buttons

                        // 🔹 Buttons Section
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 20),
                          child: Column(
                            children: [
                              // Get Started Button
                              MouseRegion(
                                onEnter: (_) =>
                                    setState(() => _isHoveringStart = true),
                                onExit: (_) =>
                                    setState(() => _isHoveringStart = false),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.of(context)
                                          .push(_createRoute(const SignUp()));
                                    },
                                    icon: const Icon(Icons.person_add,
                                        color: Colors.white),
                                    label: Text(
                                      "Get Started",
                                      style: GoogleFonts.playfairDisplay(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _isHoveringStart
                                          ? const Color(0xFF557FC1)
                                          : const Color(0xFF6C95DA),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      elevation: 5,
                                      shadowColor: Colors.grey.shade400,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Login Button (Outlined)
                              MouseRegion(
                                onEnter: (_) =>
                                    setState(() => _isHoveringLogin = true),
                                onExit: (_) =>
                                    setState(() => _isHoveringLogin = false),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.of(context)
                                          .push(_createRoute(const Login()));
                                    },
                                    icon: const Icon(Icons.login,
                                        color: Color(0xFF6C95DA)),
                                    label: Text(
                                      "Login",
                                      style: GoogleFonts.playfairDisplay(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF6C95DA),
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                          color: _isHoveringLogin
                                              ? const Color(0xFF557FC1)
                                              : const Color(0xFF6C95DA),
                                          width: 2),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(25)),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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

// 🔹 Custom Wave Top
class WaveClipperTop extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 40);
    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height - 40);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
        firstEndPoint.dx, firstEndPoint.dy);
    var secondControlPoint = Offset(3 * size.width / 4, size.height - 80);
    var secondEndPoint = Offset(size.width, size.height - 20);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy,
        secondEndPoint.dx, secondEndPoint.dy);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
