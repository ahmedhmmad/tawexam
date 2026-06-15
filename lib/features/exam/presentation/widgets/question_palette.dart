import 'package:flutter/material.dart';

/// Grid of question numbers with answered/flagged/current states. Optionally
/// shows a legend and an "unanswered only" filter so students can quickly find
/// and return to the questions they still need to answer.
class QuestionPalette extends StatefulWidget {
  const QuestionPalette({
    required this.totalQuestions,
    required this.currentIndex,
    required this.answeredQuestionIds,
    required this.flaggedQuestionIds,
    required this.questionIds,
    required this.onTap,
    this.accent = const Color(0xFF4F46E5),
    this.withFilter = false,
    super.key,
  });

  final int totalQuestions;
  final int currentIndex;
  final Set<String> answeredQuestionIds;
  final Set<String> flaggedQuestionIds;
  final List<String> questionIds;
  final ValueChanged<int> onTap;
  final Color accent;
  final bool withFilter;

  @override
  State<QuestionPalette> createState() => _QuestionPaletteState();
}

class _QuestionPaletteState extends State<QuestionPalette> {
  bool _unansweredOnly = false;

  bool _isAnswered(int index) => widget.answeredQuestionIds.contains(widget.questionIds[index]);

  @override
  Widget build(BuildContext context) {
    final indices = List.generate(widget.totalQuestions, (i) => i)
        .where((i) => !_unansweredOnly || !_isAnswered(i))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.withFilter) ...[
          _Legend(accent: widget.accent),
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilterChip(
              selected: _unansweredOnly,
              label: const Text('غير المجابة فقط'),
              avatar: Icon(
                _unansweredOnly ? Icons.filter_alt : Icons.filter_alt_outlined,
                size: 18,
              ),
              onSelected: (v) => setState(() => _unansweredOnly = v),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (indices.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'تمت الإجابة على جميع الأسئلة 🎉',
                style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold),
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 52,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: indices.length,
            itemBuilder: (context, i) {
              final index = indices[i];
              return _PaletteButton(
                label: '${index + 1}',
                state: _stateFor(index),
                accent: widget.accent,
                onTap: () => widget.onTap(index),
              );
            },
          ),
      ],
    );
  }

  _CellState _stateFor(int index) {
    if (index == widget.currentIndex) return _CellState.current;
    if (widget.flaggedQuestionIds.contains(widget.questionIds[index])) return _CellState.flagged;
    if (_isAnswered(index)) return _CellState.answered;
    return _CellState.unanswered;
  }
}

enum _CellState { current, answered, flagged, unanswered }

class _PaletteButton extends StatelessWidget {
  const _PaletteButton({
    required this.label,
    required this.state,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final _CellState state;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (state) {
      _CellState.current => (accent, Colors.white, accent),
      _CellState.answered => (Colors.green.shade500, Colors.white, Colors.green.shade500),
      _CellState.flagged => (Colors.amber.shade600, Colors.white, Colors.amber.shade600),
      _CellState.unanswered => (Colors.white, Colors.grey.shade700, Colors.grey.shade300),
    };
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border),
        ),
        child: Center(
          child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        _LegendItem(color: accent, label: 'الحالي'),
        _LegendItem(color: Colors.green.shade500, label: 'مجاب'),
        _LegendItem(color: Colors.amber.shade600, label: 'معلّم'),
        _LegendItem(color: Colors.grey.shade300, label: 'غير مجاب'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 14, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
      ],
    );
  }
}
