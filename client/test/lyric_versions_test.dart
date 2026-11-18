import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:song_language_lab/features/library/library_page.dart';

void main() {
  testWidgets('adding, switching and deleting lyric versions is explicit', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var count = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: LibraryPage(
          pickFile: (_) async {
            final text = ++count == 1
                ? 'First selected lyric'
                : 'Second selected lyric';
            return XFile.fromData(
              utf8.encode(text),
              name: 'same.txt',
              path: 'same.txt',
            );
          },
        ),
      ),
    );

    Future<void> press(Finder finder) async {
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    await press(find.text('下一句'));
    await press(find.text('导入 LRC / TXT'));
    expect(find.text('第 2 / 3 句'), findsOneWidget);
    await press(find.text('导入 LRC / TXT'));
    expect(find.text('same.txt'), findsNWidgets(2));

    await press(find.text('使用').first);
    expect(find.text('First selected lyric'), findsOneWidget);
    final deleteButtons = find.byTooltip('删除此版本');
    await tester.tap(deleteButtons.at(1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await press(find.text('取消'));
    expect(find.text('First selected lyric'), findsOneWidget);
    await tester.tap(deleteButtons.at(1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await press(find.text('确认删除'));
    expect(find.text('请选择'), findsNothing);
    expect(find.text('请从下方选择一份歌词开始练习。'), findsOneWidget);
    expect(find.text('same.txt'), findsOneWidget);
    await press(find.text('使用').last);
    expect(find.text('Second selected lyric'), findsOneWidget);
    await press(find.text('使用').first);
    expect(find.text('第 2 / 3 句'), findsOneWidget);
  });
}
