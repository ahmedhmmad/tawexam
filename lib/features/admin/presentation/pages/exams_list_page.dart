// lib/features/admin/presentation/pages/exams_list_page.dart
import 'package:flutter/material.dart';

import '../../domain/entities/admin_exam.dart';

class ExamsListPage extends StatelessWidget {
  const ExamsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exams'), actions: [
        IconButton(icon: const Icon(Icons.add), onPressed: () {}),
      ]),
      body: const Center(child: Text('Exams list')),
    );
  }
}
