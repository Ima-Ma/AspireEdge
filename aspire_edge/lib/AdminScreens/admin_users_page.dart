import 'package:flutter/material.dart';

class AdminUsersPage extends StatelessWidget {
  const AdminUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Users")),
      body: const Center(
        child: Text("Manage User Accounts Here"),
      ),
    );
  }
}
