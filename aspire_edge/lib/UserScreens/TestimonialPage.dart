import 'package:aspire_edge/UserScreens/UserComponents/appbar.dart';
import 'package:aspire_edge/UserScreens/UserComponents/bottombar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carousel_slider/carousel_slider.dart';

class TestimonialPage extends StatefulWidget {
  const TestimonialPage({Key? key}) : super(key: key);

  @override
  _TestimonialPageState createState() => _TestimonialPageState();
}

class _TestimonialPageState extends State<TestimonialPage> {
  TextEditingController _testimonialController = TextEditingController();
  String _userName = '';
  String _userEmail = '';
  bool _isSubmitting = false;

  final List<String> _reactionIcons = ["👍", "❤️", "🔥", "👏", "😮", "😂"];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'Anonymous';
      _userEmail = prefs.getString('userEmail') ?? '';
    });
  }

  Future<void> _submitTestimonial() async {
    if (_testimonialController.text.isEmpty) return;
    setState(() => _isSubmitting = true);

    await FirebaseFirestore.instance.collection('testimonials').add({
      'userName': _userName,
      'userEmail': _userEmail,
      'content': _testimonialController.text,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending',
      'likes': {},
    });

    setState(() {
      _testimonialController.clear();
      _isSubmitting = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Thank you! Your testimonial is submitted."),
        backgroundColor: Color(0xFF6C95DA),
      ),
    );
  }

  Future<void> _reactToTestimonial(String docId, String emoji) async {
    final doc = FirebaseFirestore.instance.collection('testimonials').doc(docId);
    final snapshot = await doc.get();
    Map<String, dynamic> likes =
        Map<String, dynamic>.from(snapshot['likes'] ?? {});
    likes[_userEmail] = emoji;
    await doc.update({'likes': likes});
  }

  Widget _reactionPopup(String docId) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: _reactionIcons.map((emoji) {
        return GestureDetector(
          onTap: () {
            _reactToTestimonial(docId, emoji);
            Navigator.pop(context);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(emoji, style: const TextStyle(fontSize: 28)),
          ),
        );
      }).toList(),
    );
  }

  Widget _testimonialCard(Map<String, dynamic> data, String docId) {
    Map<String, dynamic> likes = Map<String, dynamic>.from(data['likes'] ?? {});
    List<String> emojis = likes.values.whereType<String>().toList();

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        minHeight: 180,
        maxHeight: 250, // yaha height limit ki hai
      ),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundImage: AssetImage('assets/images/usericon.jpg'),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['userName'] ?? 'Anonymous',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(
                    data['timestamp'] != null
                        ? (data['timestamp'] as Timestamp)
                            .toDate()
                            .toString()
                            .split(' ')[0]
                        : '',
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                data['content'] ?? '',
                style: const TextStyle(fontSize: 14, height: 1.4),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.emoji_emotions, color: Color(0xFF6C95DA)),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: Colors.transparent,
                      content: _reactionPopup(docId),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  );
                },
              ),
              ...emojis.map((e) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    child: Text(e, style: const TextStyle(fontSize: 20)),
                  )),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AspireAppBar(),
      backgroundColor: const Color(0xFFF4F6FF),
      body: Column(
        children: [
          // Top image
Container(
  height: height * 0.25,
  width: double.infinity,
  decoration: BoxDecoration(
    image: const DecorationImage(
      image: AssetImage('assets/testi.jpg'),
      fit: BoxFit.cover,
      colorFilter: ColorFilter.mode(
        Colors.black54, // dim the image slightly
        BlendMode.darken,
      ),
    ),
  ),
  child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Neon-style title
        Text(
          "Testimonials",
          style: GoogleFonts.playfairDisplay(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                blurRadius: 10,
                color: Colors.white,
                // offset: Offset(0, 0),
              ),
              Shadow(
                blurRadius: 20,
                color: Colors.white.withOpacity(0.5),
                // offset: Offset(0, 0),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        // Subtext
        Text(
          "See what our users are saying",
          style: GoogleFonts.playfairDisplay(
            color: Colors.white70,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 8),
        // Row of icons
        Row(
          children: const [
            Icon(FontAwesomeIcons.solidStar, color: Colors.yellow, size: 18),
            SizedBox(width: 6),
            Icon(FontAwesomeIcons.solidStar, color: Colors.yellow, size: 18),
            SizedBox(width: 6),
            Icon(FontAwesomeIcons.solidStar, color: Colors.yellow, size: 18),
            SizedBox(width: 6),
            Icon(FontAwesomeIcons.solidStarHalf, color: Colors.yellow, size: 18),
            SizedBox(width: 6),
            Icon(FontAwesomeIcons.solidStar, color: Colors.yellow, size: 18),
          ],
        ),
      ],
    ),
  ),
),


          // Floating input field
          Transform.translate(
            offset: const Offset(0, -25),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black12.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _testimonialController,
                        decoration: const InputDecoration(
                          hintText: "Share your experience...",
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FloatingActionButton(
                      onPressed: _isSubmitting ? null : _submitTestimonial,
                      mini: true,
                      backgroundColor: const Color(0xFF6C95DA),
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Icon(Icons.send, color: Colors.white),
                    )
                  ],
                ),
              ),
            ),
          ),

          // Carousel
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('testimonials')
                  .where('status', isEqualTo: 'approved')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text("No testimonials yet."));
                }

                return CarouselSlider(
                  options: CarouselOptions(
                    height: height * 0.4, // fixed height for carousel
                    autoPlay: true,
                    enlargeCenterPage: true,
                    viewportFraction: 0.85,
                  ),
                  items: docs.map((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    return _testimonialCard(data, doc.id);
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: AspireBottomBar(
        currentIndex: 4,
        onTap: (index) {
          if (index != 4) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}
