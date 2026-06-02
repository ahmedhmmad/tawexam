import 'package:flutter/material.dart';

import 'core/di/service_locator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const TawExamApp());
}

class TawExamApp extends StatelessWidget {
  const TawExamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TawExam',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E40AF)),
        useMaterial3: true,
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Center(child: Text('منصة تدريب امتحان التوجيهي')),
        ),
      ),
    );
  }
}
