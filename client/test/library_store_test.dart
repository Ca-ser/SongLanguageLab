import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';
import 'package:song_language_lab/data/library_store.dart';
import 'package:song_language_lab/domain/song.dart';

void main() {
  test('round-trips independent songs, progress and audio; deletion removes the audio', () async {
    final database = await newDatabaseFactoryMemory().openDatabase('test.db');
    addTearDown(database.close);
    final store = LibraryStore(database);
    final demo = (await store.load()).single;
    final other = Song(id: 'other', name: 'Second', versions: demo.versions)
        .useVersion('sample-original')
        .atLine('sample-original', 2)
        .withAudio('song.wav');
    await store.save(
      [demo, other],
      audioSongId: other.id,
      audio: Uint8List.fromList([1, 2, 3]),
    );
    final loaded = await store.load();
    expect(loaded.map((song) => song.name), [demo.name, 'Second']);
    expect(
      loaded.last.active?.lines.last.text,
      'Tomorrow I will sing and grow.',
    );
    expect(loaded.last.progress['sample-original'], 2);
    expect(await store.readAudio(other.id), [1, 2, 3]);
    await store.save([demo], audioSongId: other.id);
    expect(await store.readAudio(other.id), isNull);
  });
}
