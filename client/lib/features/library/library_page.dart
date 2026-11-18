import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../data/library_store.dart';
import '../../domain/lyric_parser.dart';
import '../../domain/song.dart';
import '../practice/audio_panel.dart';
import '../practice/practice_panel.dart';
import '../practice/recording_panel.dart';
import 'transcription.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key, this.pickFile, this.openLibrary});

  final Future<XFile?> Function(bool lyrics)? pickFile;
  final Future<LibraryStore> Function()? openLibrary;

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  static const maxAudioSize = 25 * 1024 * 1024;
  static const maxLyricsSize = 1024 * 1024;
  final _rng = Random.secure();
  final _memoryAudio = <String, Uint8List>{};
  List<Song> _songs = [Song.sample()];
  LibraryStore? _store;
  String _selectedSong = 'sample';
  Future<Uint8List?>? _audio;
  bool _busy = false;
  bool _loading = false;
  String? _loadError;

  Song? get _song {
    for (final song in _songs) {
      if (song.id == _selectedSong) return song;
    }
    return null;
  }

  String _id() =>
      '${DateTime.now().microsecondsSinceEpoch}-${_rng.nextInt(1 << 30)}';

  @override
  void initState() {
    super.initState();
    if (widget.openLibrary != null) {
      _loading = true;
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final store = await widget.openLibrary!();
      final songs = await store.load();
      if (!mounted) return;
      setState(() {
        _store = store;
        _songs = songs;
        _loading = false;
        _loadError = null;
        _select(songs.firstOrNull?.id ?? '');
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = '无法读取本地歌曲库，请重试。';
        });
      }
    }
  }

  void _select(String id) {
    _selectedSong = id;
    _audio = _song?.audioName == null
        ? null
        : _store?.readAudio(id) ?? Future.value(_memoryAudio[id]);
  }

  Future<void> _save(
    List<Song> songs, {
    String? fileSongId,
    Uint8List? audio,
    String? select,
  }) async {
    await _store?.save(songs, audioSongId: fileSongId, audio: audio);
    if (!mounted) return;
    setState(() {
      if (fileSongId != null) {
        if (audio == null) {
          _memoryAudio.remove(fileSongId);
        } else if (_store == null) {
          _memoryAudio[fileSongId] = audio;
        }
      }
      _songs = songs;
      if (select != null) _select(select);
      if (fileSongId == _selectedSong && audio != null) {
        _audio = Future.value(audio);
      }
    });
  }

  List<Song> _replaced(Song song) => [
    for (final current in _songs) current.id == song.id ? song : current,
  ];

  Future<void> _perform(Future<void> Function() action) async {
    if (_busy || _loading) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      if (mounted) {
        final detail = error is FormatException ? error.message : '无法完成操作，请重试。';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(detail)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _createSong() => _perform(() async {
    var name = '';
    final chosen = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建歌曲'),
        content: TextField(
          autofocus: true,
          maxLength: 100,
          decoration: const InputDecoration(labelText: '歌曲名称'),
          onChanged: (value) => name = value,
          onSubmitted: (value) => Navigator.pop(context, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, name.trim()),
            child: const Text('新建'),
          ),
        ],
      ),
    );
    if (chosen == null || chosen.isEmpty || !mounted) return;
    final song = Song(id: _id(), name: chosen);
    await _save([..._songs, song], select: song.id);
  });

  Future<bool> _confirm(String title, String message, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _deleteSong(Song song) => _perform(() async {
    if (!await _confirm('删除歌曲', '将从本机移除「${song.name}」及它的音频和歌词。', '确认删除')) {
      return;
    }
    final rest = _songs.where((item) => item.id != song.id).toList();
    await _save(rest, fileSongId: song.id, select: rest.firstOrNull?.id ?? '');
  });

  Future<void> _deleteVersion(Song song, LyricVersion version) =>
      _perform(() async {
        if (!await _confirm('删除歌词', '删除「${version.name}」？', '确认删除')) return;
        await _save(_replaced(song.deleteVersion(version.id)));
      });

  Future<void> _import(Song song, bool lyrics) => _perform(() async {
    final file = await (widget.pickFile?.call(lyrics) ?? openFile());
    if (file == null || !mounted) return;
    final name = file.name.toLowerCase();
    if (lyrics) {
      if (!name.endsWith('.lrc') && !name.endsWith('.txt')) {
        throw const FormatException('导入失败：请选择 .lrc 或 .txt 歌词。');
      }
      if (await file.length() > maxLyricsSize) {
        throw const FormatException('导入失败：歌词文件不能超过 1 MB。');
      }
      try {
        final lines = parseLyrics(
          utf8.decode(await file.readAsBytes()),
          isLrc: name.endsWith('.lrc'),
        );
        final version = LyricVersion(id: _id(), name: file.name, lines: lines);
        await _save(_replaced(song.addVersion(version)));
      } on FormatException catch (e) {
        throw FormatException('导入失败：${e.message}。请检查格式并使用 UTF-8 编码。');
      }
    } else {
      if (!RegExp(r'\.(mp3|wav|m4a|aac|ogg|flac|webm)$').hasMatch(name)) {
        throw const FormatException('请选择 MP3、WAV、M4A、AAC、OGG、FLAC 或 WebM。');
      }
      if (song.audioName != null &&
          !await _confirm('替换音频', '歌词版本和练习进度会保留。', '替换')) {
        return;
      }
      final length = await file.length();
      if (length == 0 || length > maxAudioSize) {
        throw const FormatException('音频不能为空，且不能超过 25 MB。');
      }
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      await _save(
        _replaced(song.withAudio(file.name)),
        fileSongId: song.id,
        audio: bytes,
      );
    }
  });

  Future<void> _extract(Song song, Uint8List bytes) => _perform(() async {
    if (!await _confirm('自动提取歌词', '音频将交给本机转写服务处理。结果将作为一份可选的歌词草稿。', '开始提取')) {
      return;
    }
    final lines = await transcribeAudio(bytes);
    if (!mounted) return;
    final version = LyricVersion(id: _id(), name: '自动提取草稿', lines: lines);
    await _save(_replaced(song.addVersion(version)));
  });

  @override
  Widget build(BuildContext context) {
    final song = _song;
    final version = song?.active;
    final lineIndex = version == null
        ? 0
        : (song!.progress[version.id] ?? 0).clamp(0, version.lines.length - 1);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('歌语 · Song Language Lab')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('我的歌曲', style: theme.textTheme.headlineMedium),
                const SizedBox(height: 12),
                if (_loading)
                  const LinearProgressIndicator()
                else if (_loadError != null) ...[
                  Text(_loadError!),
                  TextButton(
                    onPressed: () {
                      setState(() => _loading = true);
                      _load();
                    },
                    child: const Text('重试'),
                  ),
                ] else ...[
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (_songs.isNotEmpty)
                        DropdownButton<String>(
                          value: song?.id,
                          hint: const Text('选择歌曲'),
                          onChanged: _busy
                              ? null
                              : (id) {
                                  if (id != null) setState(() => _select(id));
                                },
                          items: [
                            for (final item in _songs)
                              DropdownMenuItem(
                                value: item.id,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 178,
                                  ),
                                  child: Text(
                                    item.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      FilledButton.tonalIcon(
                        onPressed: _busy ? null : _createSong,
                        icon: const Icon(Icons.add),
                        label: const Text('新建歌曲'),
                      ),
                      if (song != null)
                        IconButton(
                          tooltip: '删除歌曲',
                          onPressed: _busy ? null : () => _deleteSong(song),
                          icon: const Icon(Icons.delete_outline),
                        ),
                    ],
                  ),
                  if (_busy) const LinearProgressIndicator(),
                  if (song == null)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text('新建一首歌，就可以导入音频和歌词。'),
                    )
                  else ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _busy ? null : () => _import(song, false),
                          icon: const Icon(Icons.audio_file_outlined),
                          label: Text(song.audioName == null ? '选择音频' : '替换音频'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _busy ? null : () => _import(song, true),
                          icon: const Icon(Icons.lyrics_outlined),
                          label: const Text('导入 LRC / TXT'),
                        ),
                      ],
                    ),
                    if (_audio != null)
                      FutureBuilder<Uint8List?>(
                        key: ValueKey('audio-${song.id}'),
                        future: _audio,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState !=
                              ConnectionState.done) {
                            return const LinearProgressIndicator();
                          }
                          final audio = snapshot.data;
                          if (audio == null) return const Text('无法读取音频，请重新导入。');
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AudioPanel(
                                key: ObjectKey(audio),
                                bytes: audio,
                                fileName: song.audioName!,
                                lineStart: version?.lines[lineIndex].timestamp,
                                nextStart: version == null
                                    ? null
                                    : _nextTimestamp(version, lineIndex),
                              ),
                              TextButton.icon(
                                onPressed: _busy
                                    ? null
                                    : () => _extract(song, audio),
                                icon: const Icon(Icons.auto_awesome),
                                label: const Text('自动提取歌词'),
                              ),
                            ],
                          );
                        },
                      ),
                    const SizedBox(height: 16),
                    if (version == null)
                      const Text('请从下方选择一份歌词开始练习。')
                    else ...[
                      Text(
                        '正在练习 · ${version.name}',
                        style: theme.textTheme.titleLarge,
                      ),
                      PracticePanel(
                        key: ValueKey('practice-${version.id}'),
                        lines: version.lines,
                        index: lineIndex,
                        onLineChanged: _busy
                            ? null
                            : (index) => _perform(
                                () => _save(
                                  _replaced(song.atLine(version.id, index)),
                                ),
                              ),
                      ),
                      RecordingPanel(
                        key: ValueKey('record-${version.id}-$lineIndex'),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text('歌词版本', style: theme.textTheme.titleLarge),
                    if (song.versions.isEmpty) const Text('尚未导入歌词。'),
                    for (final item in song.versions)
                      ListTile(
                        key: ValueKey('version-${item.id}'),
                        contentPadding: EdgeInsets.zero,
                        title: Text(item.name),
                        subtitle: Text('${item.lines.length} 句'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              key: ValueKey('use-${item.id}'),
                              onPressed: _busy || version?.id == item.id
                                  ? null
                                  : () => _perform(
                                      () => _save(
                                        _replaced(song.useVersion(item.id)),
                                      ),
                                    ),
                              child: Text(
                                version?.id == item.id ? '使用中' : '使用',
                              ),
                            ),
                            IconButton(
                              tooltip: '删除此版本',
                              onPressed: _busy
                                  ? null
                                  : () => _deleteVersion(song, item),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Duration? _nextTimestamp(LyricVersion version, int index) {
    final current = version.lines[index].timestamp;
    if (current == null) return null;
    for (final line in version.lines.skip(index + 1)) {
      final time = line.timestamp;
      if (time != null && time > current) return time;
    }
    return null;
  }
}
