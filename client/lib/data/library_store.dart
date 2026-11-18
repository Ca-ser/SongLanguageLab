import 'dart:typed_data';

import 'package:sembast/blob.dart';
import 'package:sembast/sembast.dart';

import '../domain/song.dart';
import 'open_database_native.dart'
    if (dart.library.js_interop) 'open_database_web.dart'
    as platform;

class LibraryStore {
  LibraryStore(this._database);

  final Database _database;
  static final _library = stringMapStoreFactory
      .store('library')
      .record('songs');
  static final _audio = StoreRef<String, Blob>('audio');

  static Future<LibraryStore> open() async =>
      LibraryStore(await platform.openDatabase());

  Future<List<Song>> load() async {
    final record = await _library.get(_database);
    if (record == null) return [Song.sample()];
    return (record['items']! as List)
        .cast<Map<String, Object?>>()
        .map(Song.fromMap)
        .toList();
  }

  Future<Uint8List?> readAudio(String songId) async =>
      (await _audio.record(songId).get(_database))?.bytes;

  Future<void> save(
    List<Song> songs, {
    String? audioSongId,
    Uint8List? audio,
  }) => _database.transaction((transaction) async {
    await _library.put(transaction, {
      'items': songs.map((song) => song.toMap()).toList(),
    });
    if (audioSongId != null) {
      final record = _audio.record(audioSongId);
      if (audio == null) {
        await record.delete(transaction);
      } else {
        await record.put(transaction, Blob(audio));
      }
    }
  });
}
