import 'package:flutter/material.dart';

import '../features/library/library_page.dart';

class SongLanguageApp extends StatelessWidget {
  const SongLanguageApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: '歌语',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff34675c)),
      useMaterial3: true,
    ),
    home: const LibraryPage(),
  );
}
