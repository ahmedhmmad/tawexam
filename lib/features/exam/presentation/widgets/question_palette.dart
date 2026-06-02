import 'package:flutter/material.dart';

class QuestionPalette extends StatelessWidget {
  const QuestionPalette({
    required this.totalQuestions,
    required this.currentIndex,
    required this.answeredQuestionIds,
    required this.flaggedQuestionIds,
    required this.questionIds,
    required this.onTap,
    super.key,
  });

  final int totalQuestions;
  final int currentIndex;
  final Set<String> answeredQuestionIds;
  final Set<String> flaggedQuestionIds;
  final List<String> questionIds;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: totalQuestions,
      itemBuilder: (context, index) => _PaletteButton(
        label: '${index + 1}',
        color: _colorFor(context, index),
        onTap: () => onTap(index),
      ),
    );
  }

  Color _colorFor(BuildContext context, int index) {
    final id = questionIds[index];
    if (index == currentIndex) return Colors.blue;
    if (flaggedQuestionIds.contains(id)) return Colors.amber.shade700;
    if (answeredQuestionIds.contains(id)) return Colors.green;
    return Theme.of(context).colorScheme.surfaceContainerHighest;
  }
}

class _PaletteButton extends StatelessWidget {
  const _PaletteButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: color.computeLuminance() > 0.5
                  ? Colors.black
                  : Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
