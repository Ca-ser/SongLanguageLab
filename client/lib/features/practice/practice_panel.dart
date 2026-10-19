import 'package:flutter/material.dart';

import '../../domain/lyric_line.dart';

class PracticePanel extends StatefulWidget {
  const PracticePanel({super.key, required this.lines});
  final List<LyricLine> lines;
  @override
  State<PracticePanel> createState() => _PracticePanelState();
}

class _PracticePanelState extends State<PracticePanel> {
  int index = 0;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('第 ${index + 1} / ${widget.lines.length} 句'),
          const SizedBox(height: 16),
          Text(
            widget.lines[index].text,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          LinearProgressIndicator(value: (index + 1) / widget.lines.length),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton(
                onPressed: index == 0 ? null : () => setState(() => index--),
                child: const Text('上一句'),
              ),
              FilledButton(
                onPressed: index == widget.lines.length - 1
                    ? null
                    : () => setState(() => index++),
                child: const Text('下一句'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('听：对照原曲听这一句\n说：暂停后跟读三遍\n读：理解歌词，再尝试独立唱出'),
        ],
      ),
    ),
  );
}
