// lib/features/admin/presentation/pages/results_page.dart
import 'package:flutter/material.dart';

class ResultsPage extends StatelessWidget {
  const ResultsPage({required this.examId, super.key});

  final String examId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Results')),
      body: const Center(child: Text('Results analytics')),
    );
  }
}
