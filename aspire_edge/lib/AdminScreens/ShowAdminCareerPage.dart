import 'package:aspire_edge/AdminScreens/homecomponents/bottombar.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ShowAdminCareerPage extends StatefulWidget {
  const ShowAdminCareerPage({super.key});

  @override
  State<ShowAdminCareerPage> createState() => _ShowAdminCareerPageState();
}

class _ShowAdminCareerPageState extends State<ShowAdminCareerPage> {
  final _db = FirebaseFirestore.instance;
  bool _loading = false;

  void _showEditForm(DocumentSnapshot doc) {
    final _formKey = GlobalKey<FormState>();
    final _title = TextEditingController(text: doc['title']);
    final _description = TextEditingController(text: doc['description']);
    final _skills =
        TextEditingController(text: (doc['skills'] as List<dynamic>?)?.join(', '));
    final _educationPath = TextEditingController(text: doc['educationPath']);
    final _salaryRange = TextEditingController(text: doc['salaryRange']);
    final _level = TextEditingController(text: doc['level']);
    final _category = TextEditingController(text: doc['category']);
    final _image = TextEditingController(text: doc['image']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Career"),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                  decoration:
                      const InputDecoration(labelText: "Skills (comma separated)"),
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
                TextFormField(
                  controller: _image,
                  decoration: const InputDecoration(labelText: "Image URL (optional)"),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;
              setState(() => _loading = true);

              await _db.collection('CareerBank').doc(doc.id).update({
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
                "image": _image.text.trim(),
              });

              setState(() => _loading = false);
              Navigator.pop(context);
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Career"),
        content: const Text("Are you sure you want to delete this career?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _loading = true);
              await _db.collection('CareerBank').doc(docId).delete();
              setState(() => _loading = false);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("CareerBank Admin")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: _db
                  .collection('CareerBank')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text("No CareerBank data"));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final skills =
                        (doc['skills'] as List<dynamic>?)?.join(', ') ?? '';

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: doc['image'] != null && doc['image'] != ''
                            ? Image.network(doc['image'],
                                width: 50, height: 50, fit: BoxFit.cover)
                            : const Icon(Icons.work,
                                size: 40, color: Colors.blue),
                        title: Text(doc['title'] ?? ''),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (doc['description'] != null)
                              Text(doc['description']),
                            if (skills.isNotEmpty) Text("Skills: $skills"),
                            if (doc['educationPath'] != null)
                              Text("Education: ${doc['educationPath']}"),
                            if (doc['salaryRange'] != null)
                              Text("Salary: ${doc['salaryRange']}"),
                            if (doc['level'] != null) Text("Level: ${doc['level']}"),
                            if (doc['category'] != null)
                              Text("Category: ${doc['category']}"),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.orange),
                              onPressed: () => _showEditForm(doc),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDelete(doc.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      bottomNavigationBar: const CustomBottomBar(currentIndex: 1),
    );
  }
}
