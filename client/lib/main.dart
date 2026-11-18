import 'package:flutter/material.dart';

import 'app/app.dart';
import 'data/library_store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(SongLanguageApp(openLibrary: LibraryStore.open));
}
