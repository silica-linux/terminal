import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal/src/l10n.dart';
import 'package:terminal/src/pty.dart';
import 'package:terminal/src/window.dart';

void main() {
  Future<(FakePty, TerminalWindowState)> pump(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    FakePty? pty,
  }) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final fake = pty ?? FakePty();
    var closed = false;
    await tester.pumpWidget(
      AppLocalizationsScope(
        locale: locale,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: TerminalWindow(
            pty: fake,
            shellName: 'bash',
            onLastTabClosed: () => closed = true,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(closed, isFalse);
    return (
      fake,
      tester.state<TerminalWindowState>(find.byType(TerminalWindow)),
    );
  }

  Future<void> keys(
    WidgetTester tester,
    LogicalKeyboardKey key, {
    bool meta = false,
    bool control = false,
    bool shift = false,
  }) async {
    if (meta) await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    if (control) await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(key);
    if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    if (control) await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    if (meta) await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await tester.pump();
    await tester.pump();
  }

  testWidgets('the grid fits the window: the pseudo-terminal gets its size', (
    tester,
  ) async {
    final (pty, window) = await pump(tester);
    expect(pty.calls.first.$1, 'spawn');
    final (rows, cols) = pty.sizes[1]!;
    // 800 × 600 minus the title band and the padding, in JetBrains Mono 12 pt.
    expect(cols, inInclusiveRange(90, 120));
    expect(rows, inInclusiveRange(30, 45));
    final title = tester.widget<Text>(find.byKey(const ValueKey('title')));
    expect(title.data, 'bash — $cols×$rows');
    // Resizing the window resizes the pseudo-terminal.
    tester.view.physicalSize = const Size(500, 400);
    await tester.pump();
    final (rows2, cols2) = pty.sizes[1]!;
    expect(cols2, lessThan(cols));
    expect(rows2, lessThan(rows));
    expect(window.tabs, hasLength(1));
  });

  testWidgets('tabs: ⌘T opens, ⌃⇥ switches, ⌘W closes', (tester) async {
    final (pty, window) = await pump(tester);
    expect(find.byKey(const ValueKey('tab bar')), findsNothing);
    await keys(tester, LogicalKeyboardKey.keyT, meta: true);
    expect(window.tabs, hasLength(2));
    expect(window.current, 1);
    expect(find.byKey(const ValueKey('tab bar')), findsOneWidget);
    expect(pty.calls.where((c) => c.$1 == 'spawn'), hasLength(2));
    await keys(tester, LogicalKeyboardKey.tab, control: true);
    expect(window.current, 0);
    await tester.tap(find.byKey(const ValueKey('tab 1')));
    await tester.pump();
    expect(window.current, 1);
    await keys(tester, LogicalKeyboardKey.keyW, meta: true);
    expect(window.tabs, hasLength(1));
    expect(pty.calls.where((c) => c.$1 == 'close').single.$2, 2);
    expect(find.byKey(const ValueKey('tab bar')), findsNothing);
  });

  testWidgets('find: ⌘F, matches counted, Esc closes', (tester) async {
    final (pty, _) = await pump(tester);
    pty.output(1, 'one fish\r\ntwo FISH\r\nred');
    await tester.pump();
    await keys(tester, LogicalKeyboardKey.keyF, meta: true);
    expect(find.byKey(const ValueKey('find bar')), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('find field')), 'fish');
    await tester.pump();
    expect(find.text('2 of 2'), findsOneWidget);
    await keys(tester, LogicalKeyboardKey.enter);
    expect(find.text('1 of 2'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('find field')), 'cat');
    await tester.pump();
    expect(find.text('No matches'), findsOneWidget);
    await keys(tester, LogicalKeyboardKey.escape);
    expect(find.byKey(const ValueKey('find bar')), findsNothing);
  });

  testWidgets('a mouse selection is copied with ⌘C', (tester) async {
    final (pty, _) = await pump(tester);
    pty.output(1, 'copy me please');
    await tester.pump();
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    await keys(tester, LogicalKeyboardKey.keyA, meta: true);
    await keys(tester, LogicalKeyboardKey.keyC, meta: true);
    expect(copied, contains('copy me please'));
  });

  testWidgets('in Italian: tabs and the missing service speak Italian', (
    tester,
  ) async {
    final pty = FakePty()..spawnError = const PtyUnavailable();
    final (_, window) = await pump(
      tester,
      locale: const Locale('it'),
      pty: pty,
    );
    final text = [
      for (var y = 0; y < window.session.terminal.buffer.height; y++)
        window.session.terminal.buffer.lines[y].getText(),
    ].join();
    expect(text, contains('scrivania di Silica'));
    expect(l10n.newTab, 'Nuovo pannello');
    useLocale(const Locale('en'));
  });

  testWidgets('the empty title band moves the window', (tester) async {
    final calls = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('silica/window', JSONMethodCodec()),
      (call) async {
        calls.add(call.method);
        return null;
      },
    );
    await pump(tester);
    final band = tester.getRect(find.byKey(const ValueKey('title band')));
    final gesture = await tester.startGesture(
      band.centerLeft + const Offset(20, 0),
      kind: PointerDeviceKind.mouse,
    );
    await gesture.moveBy(const Offset(40, 0));
    await gesture.up();
    await tester.pump();
    expect(calls, contains('startMove'));
  });
}
