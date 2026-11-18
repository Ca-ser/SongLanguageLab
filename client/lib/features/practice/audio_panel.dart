import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class AudioPanel extends StatefulWidget {
  const AudioPanel({
    super.key,
    required this.bytes,
    required this.fileName,
    this.lineStart,
    this.nextStart,
  });

  final Uint8List bytes;
  final String fileName;
  final Duration? lineStart;
  final Duration? nextStart;

  @override
  State<AudioPanel> createState() => _AudioPanelState();
}

class _AudioPanelState extends State<AudioPanel> {
  final _player = AudioPlayer();
  final _listeners = <StreamSubscription<dynamic>>[];
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _playing = false;
  bool _loaded = false;
  bool _busy = false;
  bool _seeking = false;
  bool _loop = false;
  double _speed = 1;
  String? _error;

  @override
  void initState() {
    super.initState();
    _listeners.addAll([
      _player.onDurationChanged.listen((duration) {
        if (mounted) setState(() => _duration = duration);
      }),
      _player.onPlayerStateChanged.listen((state) {
        if (mounted) setState(() => _playing = state == PlayerState.playing);
      }),
      _player.onPositionChanged.listen((position) {
        if (!mounted) return;
        if (!_seeking) setState(() => _position = position);
        final end = widget.nextStart;
        if (_loop && end != null && position >= end) unawaited(_seekLoop());
      }),
      _player.onPlayerComplete.listen((_) {
        if (!mounted) return;
        if (_loop) {
          unawaited(_seekLoop(restart: true));
        } else {
          setState(() => _position = Duration.zero);
        }
      }),
    ]);
  }

  @override
  void didUpdateWidget(covariant AudioPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_loop &&
        (widget.lineStart != oldWidget.lineStart ||
            widget.nextStart != oldWidget.nextStart)) {
      _loop = false;
      unawaited(_run(_player.pause));
    }
  }

  Future<void> _seekLoop({bool restart = false}) async {
    if (_seeking || !mounted || !_loop) return;
    final start = widget.lineStart;
    if (start == null) return;
    _seeking = true;
    try {
      await _player.seek(start);
      if (restart && mounted && _loop) await _player.resume();
    } catch (_) {
      if (mounted) {
        setState(() {
          _loop = false;
          _error = '单句循环失败。';
        });
      }
    } finally {
      _seeking = false;
    }
  }

  Future<void> _run(Future<void> Function() operation) async {
    if (_busy || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await operation();
    } catch (_) {
      if (mounted) {
        setState(() {
          _loop = false;
          _error = '无法播放音频。请试用 MP3 或 WAV。';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _play({Duration? start}) async {
    if (!_loaded) {
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.play(
        BytesSource(widget.bytes, mimeType: audioMimeType(widget.fileName)),
        position: start,
      );
      _loaded = true;
      if (_speed != 1) await _player.setPlaybackRate(_speed);
    } else {
      if (start != null) await _player.seek(start);
      await _player.resume();
    }
    if (mounted && _duration == Duration.zero) {
      final duration = await _player.getDuration();
      if (mounted && duration != null) setState(() => _duration = duration);
    }
  }

  Future<void> _toggleLoop() => _run(() async {
    if (_loop) {
      setState(() => _loop = false);
      await _player.pause();
      return;
    }
    final start = widget.lineStart;
    if (start == null) return;
    if (_duration > Duration.zero && start >= _duration) {
      setState(() => _error = '该句时间超过音频长度。');
      return;
    }
    setState(() => _loop = true);
    await _play(start: start);
    if (mounted && _duration > Duration.zero && start >= _duration) {
      await _player.pause();
      if (mounted) {
        setState(() {
          _loop = false;
          _error = '该句时间超过音频长度。';
        });
      }
    }
  });

  @override
  void dispose() {
    for (final listener in _listeners) {
      unawaited(listener.cancel());
    }
    unawaited(_player.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final max = _duration.inMilliseconds.toDouble();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.fileName, overflow: TextOverflow.ellipsis),
            if (max > 0)
              Slider(
                value: _position.inMilliseconds.toDouble().clamp(0.0, max),
                max: max,
                onChanged: _busy || _loop
                    ? null
                    : (value) => _run(
                        () =>
                            _player.seek(Duration(milliseconds: value.round())),
                      ),
              ),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton.tonalIcon(
                  onPressed: _busy
                      ? null
                      : () => _run(() async {
                          if (_playing) {
                            setState(() => _loop = false);
                            await _player.pause();
                          } else {
                            await _play();
                          }
                        }),
                  icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
                  label: Text(_playing ? '暂停' : '播放歌曲'),
                ),
                OutlinedButton(
                  onPressed: _busy || widget.lineStart == null
                      ? null
                      : _toggleLoop,
                  child: Text(_loop ? '停止循环' : '循环当前句'),
                ),
                DropdownButton<double>(
                  value: _speed,
                  onChanged: _busy
                      ? null
                      : (value) {
                          if (value != null) {
                            _run(() async {
                              if (_loaded) await _player.setPlaybackRate(value);
                              if (mounted) setState(() => _speed = value);
                            });
                          }
                        },
                  items: [
                    for (final speed in [0.75, 1.0, 1.25])
                      DropdownMenuItem(value: speed, child: Text('$speed×')),
                  ],
                ),
              ],
            ),
            if (widget.lineStart == null) const Text('逐句循环需要带时间戳的歌词。'),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
    );
  }
}

String audioMimeType(String name) =>
    switch (name.split('.').last.toLowerCase()) {
      'wav' => 'audio/wav',
      'm4a' => 'audio/mp4',
      'aac' => 'audio/aac',
      'ogg' => 'audio/ogg',
      'flac' => 'audio/flac',
      'webm' => 'audio/webm',
      _ => 'audio/mpeg',
    };
