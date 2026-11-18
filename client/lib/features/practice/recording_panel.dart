import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';

import 'recording_path_native.dart'
    if (dart.library.js_interop) 'recording_path_web.dart'
    as platform;

class RecordingPanel extends StatefulWidget {
  const RecordingPanel({super.key});

  @override
  State<RecordingPanel> createState() => _RecordingPanelState();
}

class _RecordingPanelState extends State<RecordingPanel> {
  AudioRecorder? _recorder;
  AudioPlayer? _player;
  StreamSubscription<PlayerState>? _playerStates;
  Timer? _limit;
  Uint8List? _clip;
  bool _recording = false;
  bool _playing = false;
  bool _busy = false;
  String? _error;

  Future<void> _act(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (_) {
      if (mounted) setState(() => _error = '录音或回放失败，请检查麦克风权限和音频设备。');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _start() => _act(() async {
    final recorder = _recorder ??= AudioRecorder();
    if (!await recorder.hasPermission()) {
      if (mounted) setState(() => _error = '请允许麦克风访问后再试。');
      return;
    }
    if (!mounted) return;
    await _player?.stop();
    final path = await platform.recordingPath();
    if (!mounted) return;
    await recorder.start(
      const RecordConfig(encoder: AudioEncoder.wav, numChannels: 1),
      path: path,
    );
    if (!mounted) return;
    setState(() => _recording = true);
    _limit = Timer(const Duration(minutes: 1), _stop);
  });

  Future<void> _stop() => _act(() async {
    _limit?.cancel();
    final String? path;
    try {
      path = await _recorder?.stop();
    } finally {
      if (mounted) setState(() => _recording = false);
    }
    if (path == null || path.isEmpty) return;
    try {
      final bytes = await XFile(path).readAsBytes();
      if (mounted && bytes.isNotEmpty) setState(() => _clip = bytes);
    } finally {
      await platform.removeRecording(path);
    }
  });

  Future<void> _play() => _act(() async {
    final clip = _clip;
    if (clip == null) return;
    final player = _player ??= AudioPlayer();
    _playerStates ??= player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _playing = state == PlayerState.playing);
    });
    if (_playing) {
      await player.stop();
    } else {
      await player.play(BytesSource(clip, mimeType: 'audio/wav'));
    }
  });

  @override
  void dispose() {
    _limit?.cancel();
    unawaited(_playerStates?.cancel());
    unawaited(_player?.dispose());
    unawaited(_disposeRecorder());
    super.dispose();
  }

  Future<void> _disposeRecorder() async {
    final recorder = _recorder;
    if (recorder == null) return;
    try {
      if (await recorder.isRecording()) await recorder.cancel();
    } finally {
      await recorder.dispose();
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          OutlinedButton.icon(
            onPressed: _busy
                ? null
                : _recording
                ? _stop
                : _start,
            icon: Icon(_recording ? Icons.stop : Icons.mic_none),
            label: Text(_recording ? '结束录音' : '跟读录音'),
          ),
          if (_clip != null)
            TextButton(
              onPressed: _recording || _busy ? null : _play,
              child: Text(_playing ? '停止回放' : '回放录音'),
            ),
        ],
      ),
      if (_recording) const Text('录音中，最多 1 分钟。'),
      if (_error != null)
        Text(
          _error!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
    ],
  );
}
