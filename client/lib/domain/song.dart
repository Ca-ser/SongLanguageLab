import 'lyric_line.dart';
import 'lyric_parser.dart';

class LyricVersion {
  const LyricVersion({
    required this.id,
    required this.name,
    required this.lines,
  });

  final String id;
  final String name;
  final List<LyricLine> lines;

  factory LyricVersion.fromMap(Map<String, Object?> map) => LyricVersion(
    id: map['id']! as String,
    name: map['name']! as String,
    lines: (map['lines']! as List).cast<Map<String, Object?>>().map((line) {
      final time = line['ms'] as int?;
      return LyricLine(
        text: line['text']! as String,
        timestamp: time == null ? null : Duration(milliseconds: time),
      );
    }).toList(),
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'lines': [
      for (final line in lines)
        {'text': line.text, 'ms': line.timestamp?.inMilliseconds},
    ],
  };
}

class Song {
  const Song({
    required this.id,
    required this.name,
    this.audioName,
    this.versions = const [],
    this.activeId,
    this.progress = const {},
  });

  final String id;
  final String name;
  final String? audioName;
  final List<LyricVersion> versions;
  final String? activeId;
  final Map<String, int> progress;

  LyricVersion? get active {
    for (final version in versions) {
      if (version.id == activeId) return version;
    }
    return null;
  }

  Song addVersion(LyricVersion version) => Song(
    id: id,
    name: name,
    audioName: audioName,
    versions: [...versions, version],
    activeId: activeId,
    progress: progress,
  );

  Song useVersion(String versionId) => Song(
    id: id,
    name: name,
    audioName: audioName,
    versions: versions,
    activeId: versionId,
    progress: progress,
  );

  Song deleteVersion(String versionId) => Song(
    id: id,
    name: name,
    audioName: audioName,
    versions: versions.where((version) => version.id != versionId).toList(),
    activeId: activeId == versionId ? null : activeId,
    progress: Map.of(progress)..remove(versionId),
  );

  Song withAudio(String fileName) => Song(
    id: id,
    name: name,
    audioName: fileName,
    versions: versions,
    activeId: activeId,
    progress: progress,
  );

  Song atLine(String versionId, int line) => Song(
    id: id,
    name: name,
    audioName: audioName,
    versions: versions,
    activeId: activeId,
    progress: {...progress, versionId: line},
  );

  factory Song.fromMap(Map<String, Object?> map) => Song(
    id: map['id']! as String,
    name: map['name']! as String,
    audioName: map['audioName'] as String?,
    activeId: map['activeId'] as String?,
    progress: (map['progress'] as Map?)?.cast<String, int>() ?? {},
    versions: (map['versions']! as List)
        .cast<Map<String, Object?>>()
        .map(LyricVersion.fromMap)
        .toList(),
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'audioName': audioName,
    'activeId': activeId,
    'progress': progress,
    'versions': versions.map((version) => version.toMap()).toList(),
  };

  static Song sample() => Song(
    id: 'sample',
    name: '原创练习示例',
    activeId: 'sample-original',
    versions: [
      LyricVersion(
        id: 'sample-original',
        name: '示例原文',
        lines: parseLyrics(
          'A little light begins to glow.\nI learn a little as I go.\nTomorrow I will sing and grow.',
          isLrc: false,
        ),
      ),
    ],
  );
}
