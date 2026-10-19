import 'lyric_line.dart';

List<LyricLine> parseLyrics(String content, {required bool isLrc}) {
  final result = <LyricLine>[];
  final stamp = RegExp(r'\[(\d+):(\d{2})(?:[.:](\d{1,3}))?\]');
  for (final raw in content.replaceAll('\uFEFF', '').split(RegExp(r'\r?\n'))) {
    final line = raw.trim();
    if (line.isEmpty) continue;
    if (!isLrc) {
      result.add(LyricLine(text: line));
      continue;
    }
    if (RegExp(
      r'^\[(ar|ti|al|by|offset|length|re|ve):',
      caseSensitive: false,
    ).hasMatch(line)) {
      continue;
    }
    final matches = stamp.allMatches(line).toList();
    final text = line.replaceAll(stamp, '').trim();
    if (matches.isEmpty) {
      throw const FormatException('LRC 时间戳或歌词无效');
    }
    if (text.isEmpty) continue;
    for (final match in matches) {
      final seconds = int.parse(match[2]!);
      if (seconds > 59) throw const FormatException('秒数必须小于 60');
      final fraction = (match[3] ?? '').padRight(3, '0');
      result.add(
        LyricLine(
          text: text,
          timestamp: Duration(
            minutes: int.parse(match[1]!),
            seconds: seconds,
            milliseconds: int.parse(fraction),
          ),
        ),
      );
    }
  }
  if (result.isEmpty) throw const FormatException('歌词文件为空或没有可用歌词');
  if (isLrc) result.sort((a, b) => a.timestamp!.compareTo(b.timestamp!));
  return result;
}
