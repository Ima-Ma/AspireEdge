import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:aspire_edge/AdminScreens/admin_drawer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

class AdminResourcesPage extends StatefulWidget {
  const AdminResourcesPage({super.key});

  @override
  State<AdminResourcesPage> createState() => _AdminResourcesPageState();
}

class _AdminResourcesPageState extends State<AdminResourcesPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();

  String _selectedType = "blog";
  String? _selectedCareerBank;
  bool _loading = false;

  File? _thumbnailFile; // Selected thumbnail file
  Uint8List? _voiceFileBytes; // Selected voice file
  String? _selectedVoiceFileName;

  final Stream<QuerySnapshot> _careerbankStream =
      FirebaseFirestore.instance.collection("CareerBank").snapshots();

  // ---------------- Thumbnail for video ----------------
  Future<void> pickThumbnail() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result != null) {
      _thumbnailFile = File(result.files.single.path!);
      setState(() {});
    }
  }

  Future<String?> uploadToImgBB(File imageFile) async {
    final apiKey = "c5d09081f9eb64fdb78510b31dd6a811"; // Free ImgBB API Key
    final request = http.MultipartRequest(
        'POST', Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey'));
    request.files
        .add(await http.MultipartFile.fromPath('image', imageFile.path));
    final response = await request.send();
    final respStr = await response.stream.bytesToString();
    final data = jsonDecode(respStr);
    if (data['success'] == true) {
      return data['data']['url'];
    }
    return null;
  }

  // ---------------- Voice story file picker ----------------
  Future<void> pickVoiceFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );
    if (result != null) {
      _selectedVoiceFileName = result.files.single.name;
      _voiceFileBytes = result.files.single.bytes;
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠ No audio file selected")),
      );
    }
  }

  // ---------------- Add Resource ----------------
  Future<void> _addResource() async {
    if (!_formKey.currentState!.validate() || _selectedCareerBank == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("CareerBank category select karna zaroori hai ❗"),
        ),
      );
      return;
    }
// ---------------- Save notification ----------------
await FirebaseFirestore.instance.collection("Notifications").add({
  "title": "New Resource Added",
  "message": "A new resource '${_titleController.text}' has been added.",
  "isRead": false,
  "createdAt": FieldValue.serverTimestamp(),
});

    if (_selectedType == "video" && _thumbnailFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Video type ke liye thumbnail select karna zaroori hai ❗"),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    // ---------------- Upload thumbnail if selected ----------------
    String? thumbnailUrl;
    if (_thumbnailFile != null) {
      thumbnailUrl = await uploadToImgBB(_thumbnailFile!);
      if (thumbnailUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Thumbnail upload failed!"),
          ),
        );
        setState(() => _loading = false);
        return;
      }
    }

    // ---------------- Upload voice file to Supabase ----------------
    String? voiceUrl;
    if (_selectedType == "voice" && _voiceFileBytes != null) {
      try {
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_$_selectedVoiceFileName';
        await Supabase.instance.client.storage
            .from('VoiceUrl')
            .uploadBinary(fileName, _voiceFileBytes!);

        voiceUrl =
            Supabase.instance.client.storage.from('VoiceUrl').getPublicUrl(fileName);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Voice upload failed: $e")),
        );
        setState(() => _loading = false);
        return;
      }
    }

    // ---------------- Save to Firebase ----------------
    await FirebaseFirestore.instance.collection("resources").add({
      "title": _titleController.text.trim(),
      "description": _descriptionController.text.trim(),
      "url": _urlController.text.trim(),
      "type": _selectedType,
      "CareerBank": _selectedCareerBank,
      "thumbnail": thumbnailUrl, // existing thumbnail
      "voiceUrl": voiceUrl, // 🔹 new voice URL
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    });

    // Clear form
    _titleController.clear();
    _descriptionController.clear();
    _urlController.clear();
    _selectedType = "blog";
    _selectedCareerBank = null;
    _thumbnailFile = null;
    _voiceFileBytes = null;
    _selectedVoiceFileName = null;

    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Resource Added ✅")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Resource"),
        backgroundColor: Colors.blue.shade800,
        centerTitle: true,
      ),
      drawer: AdminDrawer(adminName: "AspireEdge Admin"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Title
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: "Title",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? "Title is required" : null,
                  ),
                  const SizedBox(height: 16),

                  // CareerBank dropdown
                  StreamBuilder<QuerySnapshot>(
                    stream: _careerbankStream,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final categories = snapshot.data!.docs;
                      return DropdownButtonFormField<String>(
                        value: _selectedCareerBank,
                        items: categories.map((doc) {
                          return DropdownMenuItem(
                            value: doc.id,
                            child: Text(doc['category'] ?? "No category"),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setState(() => _selectedCareerBank = val),
                        decoration: const InputDecoration(
                          labelText: "CareerBank Category",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        validator: (v) =>
                            v == null ? "Select a category" : null,
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Type dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    items: const [
                      DropdownMenuItem(value: "blog", child: Text("Blog")),
                      DropdownMenuItem(value: "ebook", child: Text("Ebook")),
                      DropdownMenuItem(value: "video", child: Text("Video")),
                      // DropdownMenuItem(value: "podcast", child: Text("Podcast")),
                      DropdownMenuItem(value: "voice", child: Text("Podcast")),
                    ],
                    onChanged: (val) => setState(() => _selectedType = val!),
                    decoration: const InputDecoration(
                      labelText: "Type",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.library_books),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: "Description",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 3,
                    validator: (v) => v == null || v.isEmpty
                        ? "Description is required"
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // URL
                  TextFormField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText: "Resource URL",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.link),
                    ),
                    validator: (v) => v == null || v.isEmpty
                        ? "URL is required"
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Thumbnail file picker (only for video)
                  if (_selectedType == "video")
                    Column(
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.image),
                          label: Text(_thumbnailFile == null
                              ? "Choose Thumbnail"
                              : "Thumbnail Selected"),
                          onPressed: pickThumbnail,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),

                  // Voice story file picker (only for voice)
                  if (_selectedType == "voice")
                    Column(
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.mic),
                          label: Text(_selectedVoiceFileName == null
                              ? "Choose Audio File"
                              : "Selected: $_selectedVoiceFileName"),
                          onPressed: pickVoiceFile,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),

                  const SizedBox(height: 24),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text(
                              "Add Resource",
                              style: TextStyle(fontSize: 18),
                            ),
                            onPressed: _addResource,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}



// import 'package:aspire_edge/AdminScreens/admin_drawer.dart';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class AdminResourcesPage extends StatefulWidget {
//   const AdminResourcesPage({super.key});

//   @override
//   State<AdminResourcesPage> createState() => _AdminResourcesPageState();
// }

// class _AdminResourcesPageState extends State<AdminResourcesPage> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _titleController = TextEditingController();
//   final TextEditingController _descriptionController = TextEditingController();
//   final TextEditingController _urlController = TextEditingController();
//   final TextEditingController _tagsController = TextEditingController();

//   String _selectedType = "blog";
//   String? _selectedCareerBank; // foreign key
//   bool _loading = false;

//   final Stream<QuerySnapshot> _careerbankStream =
//       FirebaseFirestore.instance.collection("CareerBank").snapshots();

//   Future<void> _addResource() async {
//     if (!_formKey.currentState!.validate() || _selectedCareerBank == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("CareerBank category select karna zaroori hai ❗"),
//         ),
//       );
//       return;
//     }
//     setState(() => _loading = true);

//     await FirebaseFirestore.instance.collection("resources").add({
//       "title": _titleController.text.trim(),
//       "description": _descriptionController.text.trim(),
//       "url": _urlController.text.trim(),
//       // "tags": _tagsController.text
//       //     .split(',')
//       //     .map((e) => e.trim())
//       //     .where((e) => e.isNotEmpty)
//       //     .toList(),
//       "type": _selectedType,
//       "CareerBank": _selectedCareerBank,
//       "createdAt": FieldValue.serverTimestamp(),
//       "updatedAt": FieldValue.serverTimestamp(),
//     });

//     _titleController.clear();
//     _descriptionController.clear();
//     _urlController.clear();
//     // _tagsController.clear();
//     _selectedType = "blog";
//     _selectedCareerBank = null;

//     setState(() => _loading = false);
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("Resource Added ✅")),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Add Resource"),
//         backgroundColor: Colors.blue.shade800,
//         centerTitle: true,
//       ),
//       drawer: AdminDrawer(adminName: "AspireEdge Admin"),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Card(
//           elevation: 4,
//           shape:
//               RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 children: [
//                   // Title
//                   TextFormField(
//                     controller: _titleController,
//                     decoration: const InputDecoration(
//                       labelText: "Title",
//                       border: OutlineInputBorder(),
//                       prefixIcon: Icon(Icons.title),
//                     ),
//                     validator: (v) =>
//                         v == null || v.isEmpty ? "Title is required" : null,
//                   ),
//                   const SizedBox(height: 16),

//                   // CareerBank dropdown
//                   StreamBuilder<QuerySnapshot>(
//                     stream: _careerbankStream,
//                     builder: (context, snapshot) {
//                       if (!snapshot.hasData) {
//                         return const Center(child: CircularProgressIndicator());
//                       }
//                       final categories = snapshot.data!.docs;
//                       return DropdownButtonFormField<String>(
//                         value: _selectedCareerBank,
//                         items: categories.map((doc) {
//                           return DropdownMenuItem(
//                             value: doc.id,
//                             child: Text(doc['category'] ?? "No category"),
//                           );
//                         }).toList(),
//                         onChanged: (val) =>
//                             setState(() => _selectedCareerBank = val),
//                         decoration: const InputDecoration(
//                           labelText: "CareerBank Category",
//                           border: OutlineInputBorder(),
//                           prefixIcon: Icon(Icons.category),
//                         ),
//                         validator: (v) =>
//                             v == null ? "Select a category" : null,
//                       );
//                     },
//                   ),
//                   const SizedBox(height: 16),

//                   // Type dropdown
//                   DropdownButtonFormField<String>(
//                     value: _selectedType,
//                     items: const [
//                       DropdownMenuItem(value: "blog", child: Text("Blog")),
//                       DropdownMenuItem(value: "ebook", child: Text("Ebook")),
//                       DropdownMenuItem(value: "video", child: Text("Video")),
//                       DropdownMenuItem(
//                           value: "podcast", child: Text("Podcast")),
//                     ],
//                     onChanged: (val) => setState(() => _selectedType = val!),
//                     decoration: const InputDecoration(
//                       labelText: "Type",
//                       border: OutlineInputBorder(),
//                       prefixIcon: Icon(Icons.library_books),
//                     ),
//                   ),
//                   const SizedBox(height: 16),

//                   // Description
//                   TextFormField(
//                     controller: _descriptionController,
//                     decoration: const InputDecoration(
//                       labelText: "Description",
//                       border: OutlineInputBorder(),
//                       prefixIcon: Icon(Icons.description),
//                     ),
//                     maxLines: 3,
//                     validator: (v) => v == null || v.isEmpty
//                         ? "Description is required"
//                         : null,
//                   ),
//                   const SizedBox(height: 16),

//                   // URL
//                   TextFormField(
//                     controller: _urlController,
//                     decoration: const InputDecoration(
//                       labelText: "Resource URL",
//                       border: OutlineInputBorder(),
//                       prefixIcon: Icon(Icons.link),
//                     ),
//                     validator: (v) => v == null || v.isEmpty
//                         ? "URL is required"
//                         : null,
//                   ),
//                   const SizedBox(height: 16),

//                   // Tags
//                   // TextFormField(
//                   //   controller: _tagsController,
//                   //   decoration: const InputDecoration(
//                   //     labelText: "Tags (comma separated)",
//                   //     border: OutlineInputBorder(),
//                   //     prefixIcon: Icon(Icons.tag),
//                   //   ),
//                   // ),
//                   const SizedBox(height: 24),

//                   // Submit button
//                   SizedBox(
//                     width: double.infinity,
//                     height: 50,
//                     child: _loading
//                         ? const Center(child: CircularProgressIndicator())
//                         : ElevatedButton.icon(
//                             icon: const Icon(Icons.add),
//                             label: const Text(
//                               "Add Resource",
//                               style: TextStyle(fontSize: 18),
//                             ),
//                             onPressed: _addResource,
//                             style: ElevatedButton.styleFrom(
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                             ),
//                           ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }









// import 'dart:io';
// import 'dart:convert';
// import 'package:aspire_edge/AdminScreens/admin_drawer.dart';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:http/http.dart' as http;

// class AdminResourcesPage extends StatefulWidget {
//   const AdminResourcesPage({super.key});

//   @override
//   State<AdminResourcesPage> createState() => _AdminResourcesPageState();
// }

// class _AdminResourcesPageState extends State<AdminResourcesPage> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _titleController = TextEditingController();
//   final TextEditingController _descriptionController = TextEditingController();
//   final TextEditingController _urlController = TextEditingController();

//   String _selectedType = "blog";
//   String? _selectedCareerBank;
//   bool _loading = false;

//   File? _thumbnailFile; // Selected thumbnail file

//   final Stream<QuerySnapshot> _careerbankStream =
//       FirebaseFirestore.instance.collection("CareerBank").snapshots();

//   // Function to pick thumbnail image
//   Future<void> pickThumbnail() async {
//     FilePickerResult? result = await FilePicker.platform.pickFiles(
//       type: FileType.image,
//     );
//     if (result != null) {
//       _thumbnailFile = File(result.files.single.path!);
//       setState(() {});
//     }
//   }

//   // Function to upload image to ImgBB free hosting
//   Future<String?> uploadToImgBB(File imageFile) async {
//     final apiKey = "c5d09081f9eb64fdb78510b31dd6a811"; // Replace with your free ImgBB API key
//     final request = http.MultipartRequest(
//         'POST', Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey'));
//     request.files
//         .add(await http.MultipartFile.fromPath('image', imageFile.path));
//     final response = await request.send();
//     final respStr = await response.stream.bytesToString();
//     final data = jsonDecode(respStr);
//     if (data['success'] == true) {
//       return data['data']['url'];
//     }
//     return null;
//   }

//   Future<void> _addResource() async {
//     if (!_formKey.currentState!.validate() || _selectedCareerBank == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("CareerBank category select karna zaroori hai ❗"),
//         ),
//       );
//       return;
//     }

//     if (_selectedType == "video" && _thumbnailFile == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("Video type ke liye thumbnail select karna zaroori hai ❗"),
//         ),
//       );
//       return;
//     }

//     setState(() => _loading = true);

//     String? thumbnailUrl;
//     if (_thumbnailFile != null) {
//       thumbnailUrl = await uploadToImgBB(_thumbnailFile!);
//       if (thumbnailUrl == null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("Thumbnail upload failed!"),
//           ),
//         );
//         setState(() => _loading = false);
//         return;
//       }
//     }

//     await FirebaseFirestore.instance.collection("resources").add({
//       "title": _titleController.text.trim(),
//       "description": _descriptionController.text.trim(),
//       "url": _urlController.text.trim(),
//       "type": _selectedType,
//       "CareerBank": _selectedCareerBank,
//       "thumbnail": thumbnailUrl, // store uploaded image URL
//       "createdAt": FieldValue.serverTimestamp(),
//       "updatedAt": FieldValue.serverTimestamp(),
//     });

//     // Clear form
//     _titleController.clear();
//     _descriptionController.clear();
//     _urlController.clear();
//     _selectedType = "blog";
//     _selectedCareerBank = null;
//     _thumbnailFile = null;

//     setState(() => _loading = false);
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("Resource Added ✅")),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Add Resource"),
//         backgroundColor: Colors.blue.shade800,
//         centerTitle: true,
//       ),
//       drawer: AdminDrawer(adminName: "AspireEdge Admin"),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Card(
//           elevation: 4,
//           shape:
//               RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 children: [
//                   // Title
//                   TextFormField(
//                     controller: _titleController,
//                     decoration: const InputDecoration(
//                       labelText: "Title",
//                       border: OutlineInputBorder(),
//                       prefixIcon: Icon(Icons.title),
//                     ),
//                     validator: (v) =>
//                         v == null || v.isEmpty ? "Title is required" : null,
//                   ),
//                   const SizedBox(height: 16),

//                   // CareerBank dropdown
//                   StreamBuilder<QuerySnapshot>(
//                     stream: _careerbankStream,
//                     builder: (context, snapshot) {
//                       if (!snapshot.hasData) {
//                         return const Center(child: CircularProgressIndicator());
//                       }
//                       final categories = snapshot.data!.docs;
//                       return DropdownButtonFormField<String>(
//                         value: _selectedCareerBank,
//                         items: categories.map((doc) {
//                           return DropdownMenuItem(
//                             value: doc.id,
//                             child: Text(doc['category'] ?? "No category"),
//                           );
//                         }).toList(),
//                         onChanged: (val) =>
//                             setState(() => _selectedCareerBank = val),
//                         decoration: const InputDecoration(
//                           labelText: "CareerBank Category",
//                           border: OutlineInputBorder(),
//                           prefixIcon: Icon(Icons.category),
//                         ),
//                         validator: (v) =>
//                             v == null ? "Select a category" : null,
//                       );
//                     },
//                   ),
//                   const SizedBox(height: 16),

//                   // Type dropdown
//                   DropdownButtonFormField<String>(
//                     value: _selectedType,
//                     items: const [
//                       DropdownMenuItem(value: "blog", child: Text("Blog")),
//                       DropdownMenuItem(value: "ebook", child: Text("Ebook")),
//                       DropdownMenuItem(value: "video", child: Text("Video")),
//                       DropdownMenuItem(
//                           value: "podcast", child: Text("Podcast")),
//                     ],
//                     onChanged: (val) => setState(() => _selectedType = val!),
//                     decoration: const InputDecoration(
//                       labelText: "Type",
//                       border: OutlineInputBorder(),
//                       prefixIcon: Icon(Icons.library_books),
//                     ),
//                   ),
//                   const SizedBox(height: 16),

//                   // Description
//                   TextFormField(
//                     controller: _descriptionController,
//                     decoration: const InputDecoration(
//                       labelText: "Description",
//                       border: OutlineInputBorder(),
//                       prefixIcon: Icon(Icons.description),
//                     ),
//                     maxLines: 3,
//                     validator: (v) => v == null || v.isEmpty
//                         ? "Description is required"
//                         : null,
//                   ),
//                   const SizedBox(height: 16),

//                   // URL
//                   TextFormField(
//                     controller: _urlController,
//                     decoration: const InputDecoration(
//                       labelText: "Resource URL",
//                       border: OutlineInputBorder(),
//                       prefixIcon: Icon(Icons.link),
//                     ),