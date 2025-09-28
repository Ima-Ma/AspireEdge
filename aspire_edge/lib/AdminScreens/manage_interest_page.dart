import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ManageInterestPage extends StatefulWidget {
  const ManageInterestPage({super.key});

  @override
  State<ManageInterestPage> createState() => _ManageInterestPageState();
}

class _ManageInterestPageState extends State<ManageInterestPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String? _editingDocId;
  String? _thumbnailBase64; // global variable for update

  void _editInterest(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    _editingDocId = doc.id;
    _titleController.text = data["title"] ?? "";
    _descriptionController.text = data["description"] ?? "";
    _thumbnailBase64 = data["thumbnail"];
    _showEditDialog();
  }

  Future<void> _updateInterest(BuildContext dialogContext) async {
    if (_editingDocId == null) return;

    await FirebaseFirestore.instance
        .collection("interest_types")
        .doc(_editingDocId)
        .update({
      "title": _titleController.text.trim(),
      "description": _descriptionController.text.trim(),
      "thumbnail": _thumbnailBase64, // ✅ updated base64 image
      "updatedAt": FieldValue.serverTimestamp(),
    });

    Navigator.pop(dialogContext); // close dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Interest updated successfully!")),
    );
  }

  Future<void> _deleteInterest(String docId) async {
    await FirebaseFirestore.instance
        .collection("interest_types")
        .doc(docId)
        .delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Interest deleted!")),
    );
  }

  void _showEditDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Future<void> _pickImage() async {
              try {
                final ImagePicker picker = ImagePicker();
                final XFile? pickedFile =
                    await picker.pickImage(source: ImageSource.gallery);

                if (pickedFile != null) {
                  final bytes = kIsWeb
                      ? await pickedFile.readAsBytes() // ✅ Web
                      : await File(pickedFile.path).readAsBytes(); // ✅ Mobile

                  setStateDialog(() {
                    _thumbnailBase64 = base64Encode(bytes);
                  });
                }
              } catch (e) {
                debugPrint("Image pick error: $e");
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to pick image: $e")),
                  );
                }
              }
            }

            return AlertDialog(
              title: const Text("Edit Interest"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // thumbnail preview
                    _thumbnailBase64 != null
                        ? Image.memory(
                            base64Decode(_thumbnailBase64!),
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.image,
                            size: 80, color: Colors.grey),

                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.photo),
                      label: const Text("Change Image"),
                    ),

                    const SizedBox(height: 12),
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: "Title"),
                    ),
                    TextField(
                      controller: _descriptionController,
                      decoration:
                          const InputDecoration(labelText: "Description"),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () => _updateInterest(dialogContext),
                  child: const Text("Update"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Interest Types"),
        backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("interest_types")
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading data"));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text("No interest types added yet."));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: data["thumbnail"] != null
                      ? Image.memory(
                          base64Decode(data["thumbnail"]),
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.image, size: 40),
                  title: Text(data["title"] ?? ""),
                  subtitle: Text(data["description"] ?? ""),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        onPressed: () => _editInterest(doc),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteInterest(doc.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
