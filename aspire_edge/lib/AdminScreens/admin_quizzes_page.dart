// import 'package:flutter/material.dart';

// class AdminQuizzesPage extends StatelessWidget {
//   const AdminQuizzesPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Quizzes")),
//       body: const Center(
//         child: Text("Manage Quizzes Here"),
//       ),
//     );
//   }
// }




import 'package:aspire_edge/AdminScreens/homecomponents/bottombar.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminQuizzesPage extends StatefulWidget {
  const AdminQuizzesPage({super.key});

  @override
  State<AdminQuizzesPage> createState() => _AdminQuizzesPageState();
}

class _AdminQuizzesPageState extends State<AdminQuizzesPage> {
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();
  final TextEditingController _option1Controller = TextEditingController();
  final TextEditingController _option2Controller = TextEditingController();
  final TextEditingController _option3Controller = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  Future<void> _addQuiz() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    await FirebaseFirestore.instance.collection("quizzes").add({
      "question": _questionController.text.trim(),
      "answer": _answerController.text.trim(),
      "options": [
        _answerController.text.trim(),
        _option1Controller.text.trim(),
        _option2Controller.text.trim(),
        _option3Controller.text.trim(),
      ],
      "createdAt": FieldValue.serverTimestamp(),
    });

    _questionController.clear();
    _answerController.clear();
    _option1Controller.clear();
    _option2Controller.clear();
    _option3Controller.clear();

    setState(() => _loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Quiz Added ✅")),
    );
  }

  Future<void> _deleteQuiz(String id) async {
    await FirebaseFirestore.instance.collection("quizzes").doc(id).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Quiz Deleted ❌")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Quizzes")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _questionController,
                    decoration: const InputDecoration(labelText: "Question"),
                    validator: (v) =>
                        v == null || v.isEmpty ? "Required" : null,
                  ),
                  TextFormField(
                    controller: _answerController,
                    decoration: const InputDecoration(
                        labelText: "Correct Answer"),
                    validator: (v) =>
                        v == null || v.isEmpty ? "Required" : null,
                  ),
                  TextFormField(
                    controller: _option1Controller,
                    decoration: const InputDecoration(labelText: "Option 1"),
                  ),
                  TextFormField(
                    controller: _option2Controller,
                    decoration: const InputDecoration(labelText: "Option 2"),
                  ),
                  TextFormField(
                    controller: _option3Controller,
                    decoration: const InputDecoration(labelText: "Option 3"),
                  ),
                  const SizedBox(height: 10),
                  _loading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _addQuiz, child: const Text("Add Quiz")),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("quizzes")
                    .orderBy("createdAt", descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(child: Text("No quizzes yet."));
                  }
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, i) {
                      final quiz = docs[i].data() as Map<String, dynamic>;
                      return Card(
                        child: ListTile(
                          title: Text(quiz["question"] ?? ""),
                          subtitle: Text("Answer: ${quiz["answer"] ?? ""}"),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteQuiz(docs[i].id),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
        bottomNavigationBar: const CustomBottomBar(currentIndex: 2),
    );
  }
}
