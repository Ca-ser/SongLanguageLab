import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<String> recordingPath() async {
  final directory = await getTemporaryDirectory();
  return '${directory.path}${Platform.pathSeparator}song-lab-${DateTime.now().microsecondsSinceEpoch}.wav';
}

Future<void> removeRecording(String path) async {
  final file = File(path);
  if (await file.exists()) await file.delete();
}
