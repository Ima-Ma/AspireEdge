// import 'package:flutter/material.dart';

// class AdminFeedbackPage extends StatelessWidget {
//   const AdminFeedbackPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Feedback")),
//       body: const Center(
//         child: Text("View & Manage User Feedback Here"),
//       ),
//     );
//   }
// }



import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminFeedbackPage extends StatelessWidget {
  const AdminFeedbackPage({super.key});

  Future<void> _deleteFeedback(String id, BuildContext context) async {
    await FirebaseFirestore.instance.collection("feedback").doc(id).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Feedback Deleted ❌")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("User Feedback")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("feedback")
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text("No feedback found."));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final fb = docs[i].data() as Map<String, dynamic>;
              return Card(
                child: ListTile(
                  title: Text(fb["name"] ?? "Unknown"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Email: ${fb["email"] ?? ""}"),
                      Text("Phone: ${fb["phone"] ?? ""}"),
                      const SizedBox(height: 5),
                      Text("Message: ${fb["message"] ?? ""}"),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteFeedback(docs[i].id, context),
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
