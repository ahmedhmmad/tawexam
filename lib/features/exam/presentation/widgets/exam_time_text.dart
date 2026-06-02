import 'package:flutter/material.dart';

class ExamTimeText extends StatelessWidget {
  const ExamTimeText({required this.remaining, super.key});

  final Duration remaining;

  @override
  Widget build(BuildContext context) {
    final text = _format(remaining);
    final isLow = remaining.inMinutes < 5;
    return Text(
      text,
      textDirection: TextDirection.ltr,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: isLow ? Theme.of(context).colorScheme.error : null,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  String _format(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}
