import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:song_language_lab/features/library/library_page.dart';

void main() {
  testWidgets('cancel preserves practice', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: LibraryPage(pickFile: (_) async => null)),
    );
    await tester.tap(find.text('下一句'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('导入 LRC / TXT'));
    await tester.pumpAndSettle();
    expect(find.text('第 2 / 3 句'), findsOneWidget);
  });

  testWidgets('invalid lyrics preserve the selected version', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LibraryPage(
          pickFile: (_) async => XFile.fromData(
            utf8.encode(''),
            name: 'song.txt',
            path: 'song.txt',
          ),
        ),
      ),
    );
    await tester.tap(find.text('下一句'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('导入 LRC / TXT'));
    await tester.pumpAndSettle();
    expect(find.textContaining('导入失败'), findsOneWidget);
    expect(find.text('第 2 / 3 句'), findsOneWidget);
  });
}
