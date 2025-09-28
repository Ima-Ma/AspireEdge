import 'package:aspire_edge/UserScreens/ChatPage.dart';
import 'package:aspire_edge/UserScreens/Quiz.dart';
import 'package:aspire_edge/UserScreens/UserComponents/appbar.dart';
import 'package:aspire_edge/UserScreens/UserComponents/bottombar.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final ScrollController _scrollControllers = ScrollController();
  final ScrollController _scrollController = ScrollController();

  final TextEditingController _searchController = TextEditingController();
  String searchQuery = "";

  List<Map<String, dynamic>> _careerBankData = []; // Firestore data store
  bool _isLoading = true; // first load ke liye spinner

  @override
  void initState() {
    super.initState();
    _loadCareerBankData();
  }

  void _onTabTapped(int index) {
    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const Quiz()),
      );
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  // Firestore se data ek baar hi load karna
  void _loadCareerBankData() async {
    final snapshot = await FirebaseFirestore.instance
        .collection("CareerBank")
        .orderBy("category")
        .get();

    final docs = snapshot.docs;

    // unique categories filter
    final Map<String, Map<String, dynamic>> uniqueCategories = {};
    for (var doc in docs) {
      final data = doc.data();
      final String category = (data['category'] ?? '').toString();
      if (!uniqueCategories.containsKey(category)) {
        uniqueCategories[category] = data;
      }
    }

    setState(() {
      _careerBankData = uniqueCategories.values.toList();
      _isLoading = false;
    });
  }

  // YouTube launcher
  void _launchYoutube(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open YouTube")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AspireAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔎 Search
            TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  searchQuery = value.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: "Search course or category",
                suffixIcon: Container(
                  margin: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.search, color: Colors.white),
                ),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Hobbies & Interests
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.interests, color: Colors.black, size: 20),
                    SizedBox(width: 6),
                    Text(
                      "Hobbies & Interests",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    _scrollControllers.animateTo(
                      _scrollControllers.offset + 150,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: const Text("See More"),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Horizontal List of Categories
            SizedBox(
              height: 100,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("interest_types")
                    .orderBy("createdAt", descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No categories found."));
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final doc = snapshot.data!.docs[index];
                      final String title = doc['title'] ?? "";
                      final String description = doc['description'] ?? "";
                      final String thumbnail = doc['thumbnail'] ?? "";

                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              barrierDismissible: true,
                              builder: (_) => Dialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: 8,
                                insetPadding: const EdgeInsets.symmetric(
                                    horizontal: 30, vertical: 40),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(20)),
                                      child: thumbnail.isNotEmpty
                                          ? Image.memory(
                                              base64Decode(thumbnail),
                                              height: 160,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              height: 160,
                                              width: double.infinity,
                                              color: Colors.grey[300],
                                              child: const Icon(Icons.image,
                                                  size: 50,
                                                  color: Colors.grey),
                                            ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            title,
                                            style: GoogleFonts.playfairDisplay(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            description,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.black87,
                                              height: 1.4,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 20),
                                          SizedBox(
                                            width: 120,
                                            child: ElevatedButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.blueAccent,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                elevation: 3,
                                              ),
                                              child: const Text(
                                                "Close",
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.grey[200],
                                backgroundImage: thumbnail.isNotEmpty
                                    ? MemoryImage(base64Decode(thumbnail))
                                    : null,
                                child: thumbnail.isEmpty
                                    ? const Icon(Icons.image,
                                        color: Colors.grey)
                                    : null,
                              ),
                              const SizedBox(height: 6),
                              Text(title,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 25),

            // Top Course This Week
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.video_file,
                        color: Color(0xFF6C95DA), size: 20),
                    SizedBox(width: 6),
                    Text(
                      "Top Course This Week",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    if (_scrollController.hasClients) {
                      _scrollController.animateTo(
                        _scrollController.offset + 240,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Row(
                    children: const [
                      Text(
                        "See More",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios,
                          size: 14, color: Colors.black),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Horizontal Course List from "resources"
            SizedBox(
              height: 210,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("resources")
                    .orderBy("createdAt", descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                        child: Text("No courses found."));
                  }

                  final docs = snapshot.data!.docs;

                  return ListView.builder(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data =
                          docs[index].data() as Map<String, dynamic>;
                      final String title = data['title'] ?? '';
                      final String type = data['type'] ?? '';
                      final String url = data['url'] ?? '';
                      final String description =
                          data['description'] ?? '';

                      return Container(
                        width: 220,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF6C95DA),
                              Color(0xFFa3c4f3),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 8,
                              offset: const Offset(2, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(18),
                                topRight: Radius.circular(18),
                              ),
                              child: type == "image"
                                  ? Image.network(
                                      url,
                                      height: 110,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    )
                                  : type == "video"
                                      ? GestureDetector(
                                          onTap: () {
                                            _launchYoutube(url);
                                          },
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              Image.network(
                                                "https://img.youtube.com/vi/${YoutubePlayer.convertUrlToId(url)}/0.jpg",
                                                height: 110,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                              ),
                                              const Icon(
                                                  Icons.play_circle_fill,
                                                  color: Colors.white,
                                                  size: 40),
                                            ],
                                          ),
                                        )
                                      : Container(
                                          height: 110,
                                          color: Colors.blue.shade50,
                                          child: const Center(
                                            child: Icon(
                                                Icons.picture_as_pdf,
                                                color: Colors.red,
                                                size: 40),
                                          ),
                                        ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.book,
                                          color: Colors.white,
                                          size: 16),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          title,
                                          style: const TextStyle(
                                              fontWeight:
                                                  FontWeight.bold,
                                              fontSize: 14,
                                              color: Colors.white),
                                          maxLines: 1,
                                          overflow:
                                              TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    description,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white
                                          .withOpacity(0.9),
                                    ),
                                    maxLines: 2,
                                    overflow:
                                        TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 25),

            // Course List
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: const [
                Icon(Icons.menu_book,
                    color: Color(0xFF6C95DA), size: 20),
                SizedBox(width: 6),
                Text(
                  "Course List",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // CareerBank Local Filter
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Builder(
                builder: (_) {
                  // apply search filter
                  List<Map<String, dynamic>> filteredList =
                      _careerBankData;

                  if (searchQuery.isNotEmpty) {
                    filteredList = filteredList.where((data) {
                      final String category =
                          (data['category'] ?? '')
                              .toString()
                              .toLowerCase();
                      final String description =
                          (data['description'] ?? '')
                              .toString()
                              .toLowerCase();
                      final String level =
                          (data['level'] ?? '')
                              .toString()
                              .toLowerCase();
                      final List skills = data['skills'] ?? [];

                      return category.contains(searchQuery) ||
                          description.contains(searchQuery) ||
                          level.contains(searchQuery) ||
                          skills.any((skill) => skill
                              .toString()
                              .toLowerCase()
                              .contains(searchQuery));
                    }).toList();
                  }

                  if (filteredList.isEmpty) {
                    return const Center(
                        child: Text("No results found.",
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500)));
                  }

                  return Column(
                    children: filteredList.map((data) {
                      final String category = data['category'] ?? '';
                      final String description =
                          data['description'] ?? '';
                      final String level = data['level'] ?? '';
                      final List skills = data['skills'] ?? [];

                      IconData iconData;
                      switch (category.toLowerCase()) {
                        case 'administration':
                          iconData = Icons.admin_panel_settings;
                          break;
                        case 'data analysis':
                          iconData = Icons.analytics;
                          break;
                        case 'development':
                          iconData = Icons.code;
                          break;
                        case 'engineering':
                          iconData = Icons.engineering;
                          break;
                        default:
                          iconData = Icons.school;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF6C95DA),
                                Color(0xFFAECBF5),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    Colors.blueAccent.withOpacity(0.3),
                                blurRadius: 12,
                                spreadRadius: 1,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color:
                                      Colors.white.withOpacity(0.2),
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                child:
                                    Icon(iconData, color: Colors.white),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text("Category: $category",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: Colors.white)),
                                    const SizedBox(height: 4),
                                    Text("Description: $description",
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.white70)),
                                    const SizedBox(height: 6),
                                    Text("Level: $level",
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.white)),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: skills.map<Widget>((skill) {
                                        return Container(
                                          padding: const EdgeInsets
                                                  .symmetric(
                                              horizontal: 8,
                                              vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white
                                                .withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            "Skill: ${skill.toString()}",
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10),
                                          ),
                                        );
                                      }).toList(),
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
          ],
        ),
      ),

      floatingActionButton: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.pushNamed(context, '/ChatPage');
          },
          backgroundColor: Colors.white,
          elevation: 5,
          child: ClipOval(
            child: Image.asset(
              "assets/images/geminiicon.png",
              width: 35,
              height: 35,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),

      bottomNavigationBar: AspireBottomBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
