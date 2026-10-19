import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:file_selector/file_selector.dart';
import 'package:song_language_lab/features/library/library_page.dart';

void main() {
  testWidgets('cancel preserves practice', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: LibraryPage(pickFile: (_) async => null)),
    );
    await tester.tap(find.text('下一句'));
    await tester.pump();
    await tester.tap(find.text('导入 LRC / TXT'));
    await tester.pumpAndSettle();
    expect(find.text('第 2 / 3 句'), findsOneWidget);
  });
  testWidgets('import resets practice and invalid file reports error', (
    tester,
  ) async {
    var invalid = false;
    await tester.pumpWidget(
      MaterialApp(
        home: LibraryPage(
          pickFile: (_) async => XFile.fromData(
            utf8.encode(invalid ? '' : '新歌词\n第二句'),
            name: 'song.txt',
            path: 'song.txt',
          ),
        ),
      ),
    );
    await tester.tap(find.text('下一句'));
    await tester.pump();
    await tester.tap(find.text('导入 LRC / TXT'));
    await tester.pumpAndSettle();
    expect(find.text('第 1 / 2 句'), findsOneWidget);
    expect(find.text('新歌词'), findsOneWidget);
    invalid = true;
    await tester.tap(find.text('导入 LRC / TXT'));
    await tester.pumpAndSettle();
    expect(find.textContaining('导入失败'), findsOneWidget);
    expect(find.text('第 1 / 2 句'), findsOneWidget);
  });
}
