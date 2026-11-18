import 'package:flutter/material.dart';

import '../data/library_store.dart';
import '../features/library/library_page.dart';

class SongLanguageApp extends StatelessWidget {
  const SongLanguageApp({super.key, this.openLibrary});

  final Future<LibraryStore> Function()? openLibrary;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: '歌语',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      useMaterial3: true,
    ),
    home: LibraryPage(openLibrary: openLibrary),
  );
}
