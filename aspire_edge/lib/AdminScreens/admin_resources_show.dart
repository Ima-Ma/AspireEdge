import 'package:aspire_edge/AdminScreens/admin_drawer.dart';
import 'package:aspire_edge/AdminScreens/homecomponents/bottombar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminResourcesShowPage extends StatelessWidget {
  const AdminResourcesShowPage({super.key});

  Future<void> deleteResource(String id) async {
    await FirebaseFirestore.instance.collection("resources").doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Resources"),
        backgroundColor: Colors.blue.shade800,
        centerTitle: true,
      ),
      drawer: AdminDrawer(adminName: "AspireEdge Admin"),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("resources")
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No Resources Found ❗",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final resources = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: resources.length,
            itemBuilder: (context, index) {
              final doc = resources[index];
              final data = doc.data() as Map<String, dynamic>;

              final title = data["title"] ?? "";
              final description = data["description"] ?? "";
              final type = data["type"] ?? "";
              final url = data["url"] ?? "";
              final thumbnail = data["thumbnail"];
              final voiceUrl = data["voiceUrl"];
              final careerBank = data["CareerBank"] ?? "";

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: type == "video" && thumbnail != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            thumbnail,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(
                          type == "voice"
                              ? Icons.mic
                              : type == "ebook"
                                  ? Icons.menu_book
                                  : Icons.article,
                          size: 40,
                          color: Colors.blue.shade700,
                        ),
                  title: Text(
                    title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(description,
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text("Type: $type | Category: $careerBank",
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w500)),
                      if (voiceUrl != null)
                        Text("🎧 Voice file uploaded",
                            style: TextStyle(
                                fontSize: 12, color: Colors.green.shade700)),
                      if (url.isNotEmpty)
                        Text("🔗 $url",
                            style: const TextStyle(
                                fontSize: 12, color: Colors.blue)),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirm = await showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text("Confirm Delete"),
                          content: const Text(
                              "Are you sure you want to delete this resource?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text("Delete",
                                  style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await deleteResource(doc.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Resource deleted ✅")),
                        );
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: const CustomBottomBar(currentIndex: 3),
    );
  }
}
