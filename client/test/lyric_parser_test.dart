import 'package:flutter_test/flutter_test.dart';
import 'package:song_language_lab/domain/lyric_parser.dart';

void main() {
  test('TXT removes BOM and empty lines', () {
    expect(parseLyrics('\uFEFF你好\n\n世界', isLrc: false).map((e) => e.text), [
      '你好',
      '世界',
    ]);
  });
  test('LRC expands timestamps and sorts', () {
    final lines = parseLyrics(
      '[ar:demo]\n[00:02.005][00:01.50]Hello',
      isLrc: true,
    );
    expect(lines.map((e) => e.timestamp!.inMilliseconds), [1500, 2005]);
  });
  test('empty and malformed input rejected', () {
    for (final value in ['', '[00:61.00]wrong', '[ar:demo]']) {
      expect(() => parseLyrics(value, isLrc: true), throwsFormatException);
    }
  });
}
