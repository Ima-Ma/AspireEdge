import 'package:aspire_edge/UserScreens/UserComponents/appbar.dart';
import 'package:aspire_edge/UserScreens/UserComponents/bottombar.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Notifi extends StatefulWidget {
  const Notifi({Key? key}) : super(key: key);

  @override
  _NotifiState createState() => _NotifiState();
}

class _NotifiState extends State<Notifi> {
  Future<void> markAsRead(String docId) async {
    await FirebaseFirestore.instance
        .collection("Notifications")
        .doc(docId)
        .update({"isRead": true});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text(
      //     "Notifications",
      //     style: TextStyle(fontWeight: FontWeight.bold),
      //   ),
      //   backgroundColor: const Color(0xFF6C95DA),
      //   elevation: 0,
      // ),
      appBar: AspireAppBar(),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("Notifications")
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data!.docs;

          if (notifications.isEmpty) {
            return const Center(child: Text("No notifications"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              var notif = notifications[index];
              Map<String, dynamic> data = notif.data() as Map<String, dynamic>;

              bool isRead = data['isRead'] ?? false;
              String title = data['title'] ?? "";
              String message = data['message'] ?? "";
              Timestamp? createdAt = data['createdAt'];
              String? thumbnail =
                  data.containsKey('thumbnail') ? data['thumbnail'] : null;

              DateTime? time = createdAt?.toDate();
              String formattedTime = time != null
                  ? DateFormat('dd MMM, hh:mm a').format(time)
                  : "";

              return Card(
                elevation: 2,
                margin:
                    const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  isThreeLine: true,
                  onTap: () => markAsRead(notif.id),
                  leading: thumbnail != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            thumbnail,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        )
                      : CircleAvatar(
                          backgroundColor: const Color(0xFF6C95DA),
                          child: const Icon(Icons.notifications,
                              color: Colors.white),
                        ),
                  title: Text(
                    title,
                    style: TextStyle(
                      fontWeight:
                          isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      Text(message),
                      const SizedBox(height: 4),
                      Text(
                        formattedTime,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  trailing: isRead
                      ? null
                      : Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.fiber_new,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                ),
              );
            },
          );
        },
      ),
              bottomNavigationBar: AspireBottomBar(
        currentIndex: 5,
        onTap: (index) {
          if (index != 5) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}
