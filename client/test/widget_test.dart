import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:song_language_lab/app/app.dart';

void main() {
  testWidgets('practice navigation and boundaries', (tester) async {
    await tester.pumpWidget(const SongLanguageApp());
    expect(find.text('第 1 / 3 句'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '上一句'))
          .onPressed,
      isNull,
    );
    await tester.tap(find.text('下一句'));
    await tester.pump();
    expect(find.text('第 2 / 3 句'), findsOneWidget);
    await tester.tap(find.text('下一句'));
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '下一句'))
          .onPressed,
      isNull,
    );
  });
  testWidgets('small screen stays scrollable', (tester) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const SongLanguageApp());
    expect(tester.takeException(), isNull);
  });
}
