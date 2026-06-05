// lib/features/admin/presentation/pages/admin_shell_page.dart
import 'package:flutter/material.dart';

import 'exams_list_page.dart';
import 'students_page.dart';

class AdminShellPage extends StatefulWidget {
  const AdminShellPage({super.key});

  @override
  State<AdminShellPage> createState() => _AdminShellPageState();
}

class _AdminShellPageState extends State<AdminShellPage> {
  int _index = 0;

  static const _destinations = [
    NavigationRailDestination(
        icon: Icon(Icons.assignment), label: Text('Exams')),
    NavigationRailDestination(
        icon: Icon(Icons.people), label: Text('Students')),
    NavigationRailDestination(
        icon: Icon(Icons.bar_chart), label: Text('Results')),
  ];

  static const _pages = [
    ExamsListPage(),
    StudentsPage(),
    Center(child: Text('Results')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            labelType: NavigationRailLabelType.all,
            destinations: _destinations,
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _pages[_index]),
        ],
      ),
    );
  }
}
