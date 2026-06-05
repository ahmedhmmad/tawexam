// lib/features/admin/presentation/pages/students_page.dart
import 'package:flutter/material.dart';

class StudentsPage extends StatelessWidget {
  const StudentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Students'), actions: [
        IconButton(icon: const Icon(Icons.upload), onPressed: () {}),
        IconButton(icon: const Icon(Icons.download), onPressed: () {}),
      ]),
      body: const Center(child: Text('Students list')),
    );
  }
}
