import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../domain/lyric_line.dart';

Future<List<LyricLine>> transcribeAudio(Uint8List bytes) async {
  const configured = String.fromEnvironment('TRANSCRIPTION_ORIGIN');
  final origin = configured.isNotEmpty
      ? Uri.parse(configured)
      : kIsWeb
      ? Uri.base
      : Uri.parse('http://127.0.0.1:8787');
  final service = origin.resolve('/api/transcribe');
  final http.Response response;
  final client = http.Client();
  try {
    response = await client
        .post(
          service,
          headers: {'Content-Type': 'application/octet-stream'},
          body: bytes,
        )
        .timeout(const Duration(minutes: 10));
  } on Exception {
    throw const FormatException('无法连接本机转写服务，或处理超时。请检查测试服务后重试。');
  } finally {
    client.close();
  }
  if (response.statusCode == 404 || response.statusCode == 405) {
    throw const FormatException('当前地址未启用本机转写服务。');
  }
  final Map<String, dynamic> payload;
  try {
    payload =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  } catch (_) {
    throw const FormatException('转写服务返回了无法读取的结果。');
  }
  if (response.statusCode != 200) {
    final message = payload['detail'];
    throw FormatException(message is String ? message : '转写失败，请重试。');
  }
  final lines = <LyricLine>[
    for (final item in payload['lines'] as List)
      LyricLine(
        text: item['text'] as String,
        timestamp: Duration(milliseconds: item['startMs'] as int),
      ),
  ];
  if (lines.isEmpty) throw const FormatException('未识别到可用歌词。');
  return lines;
}
