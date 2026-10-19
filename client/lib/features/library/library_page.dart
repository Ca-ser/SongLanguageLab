import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';

import '../../domain/lyric_line.dart';
import '../../domain/lyric_parser.dart';
import '../practice/practice_panel.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key, this.pickFile});
  final Future<XFile?> Function(bool lyrics)? pickFile;
  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  List<LyricLine> lines = parseLyrics(
    'A little light begins to glow.\nI learn a little as I go.\nTomorrow I will sing and grow.',
    isLrc: false,
  );
  String title = '原创练习示例';
  String? audio;
  bool busy = false;
  int revision = 0;
  Future<void> importFile(bool lyrics) async {
    setState(() => busy = true);
    try {
      final file = await (widget.pickFile?.call(lyrics) ?? openFile());
      if (file == null) return;
      if (lyrics) {
        final name = file.name.toLowerCase();
        if (!name.endsWith('.lrc') && !name.endsWith('.txt')) {
          throw const FormatException('请选择 .lrc 或 .txt 歌词');
        }
        final parsed = parseLyrics(
          utf8.decode(await file.readAsBytes()),
          isLrc: name.endsWith('.lrc'),
        );
        if (!mounted) return;
        setState(() {
          lines = parsed;
          title = file.name;
          revision++;
        });
      } else {
        if (!RegExp(
          r'\.(mp3|wav|m4a|aac|ogg|flac)$',
          caseSensitive: false,
        ).hasMatch(file.name)) {
          throw const FormatException('请选择常见音频文件');
        }
        if (mounted) setState(() => audio = file.name);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('导入失败：$error。歌词请使用 UTF-8 编码。')));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('歌语 · Song Language Lab')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 850),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              '用一首歌，练习一门语言',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            const Text('本地歌词练习起点：导入 → 分句 → 跟读 → 试着唱下来'),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: busy ? null : () => importFile(false),
                  icon: const Icon(Icons.audio_file),
                  label: const Text('选择音频'),
                ),
                OutlinedButton.icon(
                  onPressed: busy ? null : () => importFile(true),
                  icon: const Icon(Icons.lyrics),
                  label: const Text('导入 LRC / TXT'),
                ),
              ],
            ),
            if (busy) const LinearProgressIndicator(),
            const SizedBox(height: 16),
            Text(audio == null ? '尚未选择音频' : '已选择：$audio'),
            const Text('当前为练习演示：尚未接入音频播放、录音、自动转写及持久化。文件不会上传。'),
            const SizedBox(height: 24),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            PracticePanel(key: ValueKey(revision), lines: lines),
          ],
        ),
      ),
    ),
  );
}
