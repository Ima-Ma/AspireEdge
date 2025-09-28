import 'dart:convert';
import 'package:aspire_edge/UserScreens/UserComponents/appbar.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({Key? key}) : super(key: key);

  @override
  _UserProfileState createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController contactController = TextEditingController();
  TextEditingController locationController = TextEditingController();

  String? selectedLevel;
  List<dynamic> selectedSkills = [];
  String? selectedSkillFromDropdown;

  List<dynamic> _searchResults = [];
  List<String> selectedInterests = [];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    User? user = _auth.currentUser;

    if (user != null) {
      DocumentSnapshot doc =
          await _firestore.collection("userprofile").doc(user.uid).get();
      Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

      setState(() {
        nameController.text =
            data?["UserName"] ?? prefs.getString("userName") ?? "";
        emailController.text =
            data?["Email"] ?? prefs.getString("userEmail") ?? "";
        contactController.text = data?["Contact"] ?? "";
        locationController.text = data?["Location"] ?? "";
        selectedLevel = data?["Level"];
        selectedSkillFromDropdown = data?["Skill"];

        selectedInterests = [];
        if (data?["Interests"] != null) {
          for (var item in data!["Interests"]) {
            selectedInterests.add(item.toString());
          }
        }
      });

      if (selectedLevel != null) {
        QuerySnapshot levelDocs = await _firestore
            .collection("CareerBank")
            .where("level", isEqualTo: selectedLevel)
            .get();
        if (levelDocs.docs.isNotEmpty) {
          selectedSkills = levelDocs.docs.first["skills"] ?? [];
        }
      }
    }
  }

  Future<void> searchLocation(String query) async {
    if (query.length < 3) return;
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$query&countrycodes=pk&format=json');
    final response = await http.get(url, headers: {
      'User-Agent': 'FlutterApp/1.0 (contact@example.com)',
    });

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      setState(() {
        _searchResults = data;
      });
    }
  }

  void onAreaSelect(Map<String, dynamic> item) {
    setState(() {
      locationController.text = item['display_name'];
      _searchResults = [];
    });
  }

  Future<void> _saveProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection("userprofile").doc(user.uid).set({
        "UserId": user.uid,
        "UserName": nameController.text.trim(),
        "Email": emailController.text.trim(),
        "Level": selectedLevel,
        "Skill": selectedSkillFromDropdown,
        "Contact": contactController.text.trim(),
        "Location": locationController.text.trim(),
        "Interests": selectedInterests,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString("userName", nameController.text.trim());
      await prefs.setString("userEmail", emailController.text.trim());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile saved successfully! ✅"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print("Error saving profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error saving profile. ❌"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AspireAppBar(),
      backgroundColor: const Color(0xFFF2F6FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Section
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: double.infinity,
                  height: screenHeight * 0.35,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: const AssetImage('assets/images/jobs.png'),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0.3),
                        BlendMode.darken,
                      ),
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(60),
                      bottomRight: Radius.circular(60),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  left: 130,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Aspire Edge 🎯",
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          textStyle: const TextStyle(
                            fontFamilyFallback: [
                              'NotoColorEmoji',
                              'Segoe UI Emoji',
                              'Apple Color Emoji'
                            ],
                          ),
                          shadows: const [
                            Shadow(
                                blurRadius: 5,
                                color: Colors.black54,
                                offset: Offset(2, 2)),
                          ],
                        ),
                      ),
                      Text(
                        "Your career starts here! 🚀",
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.white70,
                          textStyle: const TextStyle(
                            fontFamilyFallback: [
                              'NotoColorEmoji',
                              'Segoe UI Emoji',
                              'Apple Color Emoji'
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: -40,
                  left: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueAccent.withOpacity(0.5),
                          blurRadius: 15,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: const CircleAvatar(
                      radius: 45,
                      backgroundImage: AssetImage('assets/images/usericon.jpg'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 60),

            // Main Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Interests
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Select Your Interests ❤️",
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2B3A55),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          // Navigate or show more
                          print("See More Interests clicked");
                        },
                        icon: const Icon(Icons.arrow_forward,
                            size: 18, color: Color(0xFF2B3A55)),
                        label: const Text(
                          "See More",
                          style: TextStyle(
                            color: Color(0xFF2B3A55),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Divider(
                    color: Color(0xFF6C95DA),
                    thickness: 2,
                    endIndent: 0, // full width line
                  ),
                  const SizedBox(height: 12),

                  // Interests Chips
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection("interest_types").snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      var docs = snapshot.data!.docs;
                      if (docs.isEmpty) {
                        return const Text("No interests found.");
                      }

                      return SizedBox(
                        height: 50,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: docs.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            String title = docs[index].data().toString().contains('title')
                                ? docs[index]["title"].toString()
                                : "Unknown";

                            bool isSelected = selectedInterests.contains(title);

                            return FilterChip(
                              label: Text(
                                title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected ? Colors.white : Colors.black87,
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (val) {
                                setState(() {
                                  if (val) {
                                    selectedInterests.add(title);
                                  } else {
                                    selectedInterests.remove(title);
                                  }
                                });
                              },
                              selectedColor: const Color(0xFF6C95DA),
                              checkmarkColor: Colors.white,
                              backgroundColor: Colors.grey.shade200,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  // Career Level
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Select Your Career Level 💼",
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2B3A55),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          // Navigate or show more
                          print("See More Career Levels clicked");
                        },
                        icon: const Icon(Icons.arrow_forward,
                            size: 18, color: Color(0xFF2B3A55)),
                        label: const Text(
                          "See More",
                          style: TextStyle(
                            color: Color(0xFF2B3A55),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Divider(
                    color: Color(0xFF6C95DA),
                    thickness: 2,
                    endIndent: 0, // full width line
                  ),
                  const SizedBox(height: 12),

                  // Career Level Chips
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection("CareerBank").snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData)
                        return const CircularProgressIndicator();
                      var docs = snapshot.data!.docs;
                      if (docs.isEmpty) return const Text("No levels found.");

                      Map<String, List<dynamic>> uniqueLevels = {};
                      for (var doc in docs) {
                        String level = doc.data().toString().contains('level')
                            ? doc["level"].toString()
                            : "Unknown";
                        List<dynamic> skills = doc.data().toString().contains('skills')
                            ? doc["skills"]
                            : [];
                        if (!uniqueLevels.containsKey(level)) {
                          uniqueLevels[level] = skills;
                        }
                      }

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: uniqueLevels.entries.map((entry) {
                            String level = entry.key;
                            List<dynamic> skills = entry.value;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 5),
                              child: ChoiceChip(
                                label: Row(
                                  children: [
                                    const Icon(Icons.star,
                                        size: 16, color: Colors.yellow),
                                    const SizedBox(width: 5),
                                    Text(level),
                                  ],
                                ),
                                selected: selectedLevel == level,
                                onSelected: (bool selected) {
                                  setState(() {
                                    selectedLevel = level;
                                    selectedSkills = skills;
                                    selectedSkillFromDropdown = null;
                                  });
                                },
                                selectedColor: const Color(0xFF6C95DA),
                                backgroundColor: Colors.grey.shade300,
                                labelStyle: TextStyle(
                                  color: selectedLevel == level
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Skills Dropdown
                  if (selectedSkills.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF6C95DA)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          hint: const Text("Select Skill 🛠️"),
                          value: selectedSkillFromDropdown,
                          items: selectedSkills.map((skill) {
                            return DropdownMenuItem<String>(
                              value: skill.toString(),
                              child: Text(skill.toString()),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedSkillFromDropdown = value;
                            });
                          },
                          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6C95DA)),
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Name
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: "User Name",
                      filled: true,
                      fillColor: Colors.grey.shade200,
                      prefixIcon: const Icon(Icons.person, color: Color(0xFF6C95DA)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Email
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: "Email",
                      filled: true,
                      fillColor: Colors.grey.shade200,
                      prefixIcon: const Icon(Icons.email, color: Color(0xFF6C95DA)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 12),

                  // Contact
                  TextField(
                    controller: contactController,
                    decoration: InputDecoration(
                      labelText: "Contact Number 📞",
                      filled: true,
                      fillColor: Colors.grey.shade200,
                      prefixIcon: const Icon(Icons.phone, color: Color(0xFF6C95DA)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                  ),

                  const SizedBox(height: 12),

                  // Location with search
                  TextField(
                    controller: locationController,
                    decoration: InputDecoration(
                      labelText: "Search Location 📍",
                      filled: true,
                      fillColor: Colors.grey.shade200,
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF6C95DA)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) {
                      if (val.length > 3) searchLocation(val);
                    },
                  ),
                  const SizedBox(height: 8),
                  ..._searchResults.map((item) => ListTile(
                        leading: const Icon(Icons.location_on),
                        title: Text(item['display_name'], style: const TextStyle(fontSize: 13)),
                        onTap: () => onAreaSelect(item),
                      )),

                  const SizedBox(height: 25),

                  // Save Button
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _saveProfile,
                      icon: const Icon(Icons.save),
                      label: const Text("Save Profile 💾"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C95DA),
                        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
      
    );
  }
}
