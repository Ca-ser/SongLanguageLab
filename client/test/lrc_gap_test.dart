import 'package:flutter_test/flutter_test.dart';
import 'package:song_language_lab/domain/lyric_parser.dart';

void main() {
  test('LRC instrumental gaps do not discard usable lyrics', () {
    expect(
      parseLyrics('[00:00.00]\n[00:05.00]Hello', isLrc: true).single.text,
      'Hello',
    );
    expect(() => parseLyrics('[00:00.00]', isLrc: true), throwsFormatException);
  });
}
