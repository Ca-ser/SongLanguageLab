import 'package:flutter/material.dart';

import '../../domain/lyric_line.dart';

class PracticePanel extends StatelessWidget {
  const PracticePanel({
    super.key,
    required this.lines,
    required this.index,
    required this.onLineChanged,
  });
  final List<LyricLine> lines;
  final int index;
  final ValueChanged<int>? onLineChanged;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('第 ${index + 1} / ${lines.length} 句'),
          const SizedBox(height: 12),
          SelectableText(
            lines[index].text,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 20),
          LinearProgressIndicator(value: (index + 1) / lines.length),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: index == 0 || onLineChanged == null
                    ? null
                    : () => onLineChanged!(index - 1),
                child: const Text('上一句'),
              ),
              FilledButton(
                onPressed: index == lines.length - 1 || onLineChanged == null
                    ? null
                    : () => onLineChanged!(index + 1),
                child: const Text('下一句'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
