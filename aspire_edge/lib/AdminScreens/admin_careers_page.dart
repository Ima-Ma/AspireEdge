import 'package:aspire_edge/AdminScreens/homecomponents/bottombar.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  Future<void> addCareer(Map<String, dynamic> data) async {
    await _db.collection('CareerBank').add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

class AdminCareerPage extends StatefulWidget {
  const AdminCareerPage({super.key});

  @override
  State<AdminCareerPage> createState() => _AdminCareerPageState();
}

class _AdminCareerPageState extends State<AdminCareerPage> {
  int _selectedIndex = 1;

  final _formKey = GlobalKey<FormState>();
  final _id = TextEditingController();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _skills = TextEditingController();
  final _educationPath = TextEditingController();
  final _salaryRange = TextEditingController();
  final _level = TextEditingController();
  final _category = TextEditingController();
  // final _image = TextEditingController();

  final _fs = FirestoreService();
  bool _loading = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    await _fs.addCareer({
      "id": _id.text.trim(),
      "title": _title.text.trim(),
      "description": _description.text.trim(),
      "skills": _skills.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      "educationPath": _educationPath.text.trim(),
      "salaryRange": _salaryRange.text.trim(),
      "level": _level.text.trim(),
      "category": _category.text.trim(),
      // "image": _image.text.trim(),
    });

    setState(() => _loading = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Career Added')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Career")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // TextFormField(
                    //   controller: _id,
                    //   decoration: const InputDecoration(labelText: "ID"),
                    //   validator: (v) => v!.isEmpty ? "Required" : null,
                    // ),
                    TextFormField(
                      controller: _title,
                      decoration: const InputDecoration(labelText: "Title"),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                    TextFormField(
                      controller: _description,
                      decoration: const InputDecoration(labelText: "Description"),
                      maxLines: 3,
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                    TextFormField(
                      controller: _skills,
                      decoration: const InputDecoration(
                          labelText: "Skills (comma separated)"),
                    ),
                    TextFormField(
                      controller: _educationPath,
                      decoration: const InputDecoration(labelText: "Education Path"),
                    ),
                    TextFormField(
                      controller: _salaryRange,
                      decoration: const InputDecoration(labelText: "Salary Range"),
                    ),
                    TextFormField(
                      controller: _level,
                      decoration: const InputDecoration(labelText: "Level"),
                    ),
                    TextFormField(
                      controller: _category,
                      decoration: const InputDecoration(labelText: "Category"),
                    ),
                    // TextFormField(
                    //   controller: _image,
                    //   decoration:
                    //       const InputDecoration(labelText: "Image URL (optional)"),
                    // ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                        onPressed: _submit, child: const Text("Save Career")),
                  ],
                ),
              ),
      ),
     bottomNavigationBar: const CustomBottomBar(currentIndex: 1),
    );
  }
}
