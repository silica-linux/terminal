import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';
import 'package:terminal/src/l10n.dart';
import 'package:terminal/src/pty.dart';
import 'package:terminal/src/style.dart';
import 'package:terminal/src/window.dart';
import 'package:xterm/xterm.dart';

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
    // 800 × 600 minus the chrome (68) and the insets (10 + 27, 7 + 10), in 7 × 14 cells.
    expect(cols, (800 - 37) ~/ 7);
    expect(rows, (600 - 68 - 17) ~/ 14);
    final title = tester.widget<Text>(find.byKey(const ValueKey('title')));
    expect(title.data, 'bash — $cols×$rows');
    // Resizing the window resizes the pseudo-terminal.
    tester.view.physicalSize = const Size(500, 400);
    await tester.pump();
    final (rows2, cols2) = pty.sizes[1]!;
    expect(cols2, lessThan(cols));
    expect(rows2, lessThan(rows));
    expect(window.tabs, hasLength(1));
    // The title follows the size live: the resize arrives during layout, the title the
    // frame after.
    await tester.pump();
    final title2 = tester.widget<Text>(find.byKey(const ValueKey('title')));
    expect(title2.data, 'bash — $cols2×$rows2');
  });

  testWidgets('a new tab slides in from the right in ~550 ms', (tester) async {
    final (_, window) = await pump(tester);
    final full = tester.getSize(find.byKey(const ValueKey('tab 0'))).width;
    await keys(tester, LogicalKeyboardKey.keyT, meta: true);
    await tester.pump(const Duration(milliseconds: 100));
    final entering = tester.getSize(find.byKey(const ValueKey('tab 1'))).width;
    expect(entering, greaterThan(0));
    expect(entering, lessThan(full / 2));
    await tester.pump(const Duration(milliseconds: 500));
    final settled = tester.getSize(find.byKey(const ValueKey('tab 1'))).width;
    expect(settled, moreOrLessEquals(full / 2, epsilon: 0.5));
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('tab 1'))).dx,
      greaterThan(tester.getTopLeft(find.byKey(const ValueKey('tab 0'))).dx),
    );
    expect(window.tabs, hasLength(2));
  });

  testWidgets('an inactive window: hollow cursor and grey selection', (
    tester,
  ) async {
    await pump(tester);
    TerminalView view() =>
        tester.widget<TerminalView>(find.byType(TerminalView));
    expect(view().focusNode!.hasFocus, isTrue);
    expect(view().cursorType, TerminalCursorType.block);
    expect(view().theme.selection, lightProfile.grid.selection);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    // xterm draws the cursor hollow when the grid has no focus.
    expect(view().focusNode!.hasFocus, isFalse);
    expect(view().theme.selection, lightProfile.inactiveSelection);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(view().focusNode!.hasFocus, isTrue);
    expect(view().theme.selection, const Color(0xFFB3D7FF));
  });

  testWidgets('the find bar grows the window by 32 pt and back', (
    tester,
  ) async {
    final sizes = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('silica/window', JSONMethodCodec()),
      (call) async {
        if (call.method == 'setSize') sizes.add(call.arguments);
        return true;
      },
    );
    final (pty, _) = await pump(tester);
    pty.output(1, 'one fish\r\ntwo fish');
    await tester.pump();
    await keys(tester, LogicalKeyboardKey.keyF, meta: true);
    expect(
      tester.getSize(find.byKey(const ValueKey('find bar'))).height,
      findBarHeight,
    );
    await tester.enterText(find.byKey(const ValueKey('find field')), 'fish');
    await tester.pump();
    expect(find.text('2 of 2'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('find previous')));
    await tester.pump();
    expect(find.text('1 of 2'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('find next')));
    await tester.pump();
    expect(find.text('2 of 2'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('find done')));
    await tester.pump();
    expect(find.byKey(const ValueKey('find bar')), findsNothing);
    expect(sizes, hasLength(2));
    expect(sizes.first.toString(), contains('632'));
    expect(sizes.last.toString(), contains('568'));
  });

  testWidgets('tabs: ⌘T opens, ⌃⇥ switches, ⌘W closes', (tester) async {
    final (pty, window) = await pump(tester);
    // The tab bar is always visible, with one tab too.
    expect(find.byKey(const ValueKey('tab bar')), findsOneWidget);
    expect(find.byKey(const ValueKey('tab 0')), findsOneWidget);
    await keys(tester, LogicalKeyboardKey.keyT, meta: true);
    await tester.pumpAndSettle();
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
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tab bar')), findsOneWidget);
    expect(find.byKey(const ValueKey('tab 1')), findsNothing);
  });

  Future<TestGesture> hover(WidgetTester tester, String key) async {
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(700, 400));
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.byKey(ValueKey(key))));
    await tester.pump();
    return mouse;
  }

  testWidgets('the × shows on hover only, 18 × 18 at tab x +4', (tester) async {
    await pump(tester);
    expect(find.byKey(const ValueKey('tab close 0')), findsNothing);
    await hover(tester, 'tab 0');
    final close = find.byKey(const ValueKey('tab close 0'));
    expect(close, findsOneWidget);
    expect(tester.getSize(close), const Size(18, 18));
    expect(
      tester.getTopLeft(close).dx -
          tester.getTopLeft(find.byKey(const ValueKey('tab 0'))).dx,
      4,
    );
  });

  testWidgets('the × has a pressed state and closes the tab and its pty', (
    tester,
  ) async {
    final (pty, window) = await pump(tester);
    await keys(tester, LogicalKeyboardKey.keyT, meta: true);
    await tester.pumpAndSettle();
    final mouse = await hover(tester, 'tab 0');
    final close = find.byKey(const ValueKey('tab close 0'));
    BoxDecoration glyph() =>
        tester
                .widget<Container>(
                  find.byKey(const ValueKey('tab close glyph')),
                )
                .decoration!
            as BoxDecoration;
    expect(glyph().color, isNull);
    await mouse.moveTo(tester.getCenter(close));
    await mouse.down(tester.getCenter(close));
    await tester.pump(kPressTimeout);
    expect(glyph().color, isNotNull);
    await mouse.up();
    await tester.pump();
    await tester.pump();
    expect(window.tabs, hasLength(1));
    expect(pty.calls.where((c) => c.$1 == 'close').single.$2, 1);
    await tester.pumpAndSettle();
  });

  testWidgets('closing the last tab with the × closes the window', (
    tester,
  ) async {
    var closed = false;
    final pty = FakePty();
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      AppLocalizationsScope(
        locale: const Locale('en'),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: TerminalWindow(
            pty: pty,
            shellName: 'bash',
            onLastTabClosed: () => closed = true,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await hover(tester, 'tab 0');
    await tester.tap(find.byKey(const ValueKey('tab close 0')));
    await tester.pump();
    await tester.pump();
    expect(closed, isTrue);
  });

  testWidgets('a busy tab asks before closing; Cancel keeps it', (
    tester,
  ) async {
    final (pty, window) = await pump(tester);
    pty.busy.add(1);
    await keys(tester, LogicalKeyboardKey.keyW, meta: true);
    expect(
      find.text('Do you want to terminate running processes in this tab?'),
      findsOneWidget,
    );
    expect(window.tabs, hasLength(1));
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    expect(find.byKey(const ValueKey('close confirmation')), findsNothing);
    expect(window.tabs, hasLength(1));
    expect(pty.calls.where((c) => c.$1 == 'close'), isEmpty);
  });

  testWidgets('a busy tab: Terminate closes it (× and ⌘W alike)', (
    tester,
  ) async {
    final (pty, window) = await pump(tester);
    await keys(tester, LogicalKeyboardKey.keyT, meta: true);
    await tester.pumpAndSettle();
    pty.busy.addAll([1, 2]);
    await hover(tester, 'tab 0');
    await tester.tap(find.byKey(const ValueKey('tab close 0')));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey('close confirmation')), findsOneWidget);
    await tester.tap(find.text('Terminate'));
    await tester.pump();
    expect(window.tabs, hasLength(1));
    expect(pty.calls.where((c) => c.$1 == 'close').single.$2, 1);
    await tester.pumpAndSettle();
    await keys(tester, LogicalKeyboardKey.keyW, meta: true);
    expect(find.byKey(const ValueKey('close confirmation')), findsOneWidget);
    await tester.tap(find.text('Terminate'));
    await tester.pump();
    expect(window.tabs, isEmpty);
  });

  testWidgets('closing the window with nothing running is not asked', (
    tester,
  ) async {
    await pump(tester);
    expect(
      await SilicaWindows.handle('closeRequested', {'viewId': 0}),
      isFalse, // the embedder closes it
    );
    expect(find.byKey(const ValueKey('close confirmation')), findsNothing);
  });

  testWidgets('closing the window with a process running asks first', (
    tester,
  ) async {
    final (pty, window) = await pump(tester);
    pty.busy.add(1);
    final closing = SilicaWindows.handle('closeRequested', {'viewId': 0});
    await tester.pump();
    await tester.pump();
    expect(
      find.text('Do you want to terminate running processes in this window?'),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    expect(await closing, isTrue); // kept open
    expect(window.tabs, hasLength(1));
    expect(find.byKey(const ValueKey('close confirmation')), findsNothing);

    final again = SilicaWindows.handle('closeRequested', {'viewId': 0});
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Terminate'));
    await tester.pump();
    expect(await again, isFalse); // the embedder closes the window
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
    expect(l10n.findDone, 'Fine');
    expect(l10n.findPrevious, 'Risultato precedente');
    expect(l10n.findNext, 'Risultato successivo');
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
  testWidgets('the title is left-aligned with the proxy icon (titlebar.md)', (
    tester,
  ) async {
    await pump(tester);
    expect(tester.getSize(find.byKey(const ValueKey('title band'))).height, 32);
    final icon = tester.getRect(find.byKey(const ValueKey('title icon')));
    expect(icon.left, 81);
    expect(icon.top, 6);
    expect(icon.size, const Size(18, 18));
    final title = tester.getRect(find.byKey(const ValueKey('title')));
    expect(title.left, 100);
    expect(title.right, 800 - 10);
  });

  testWidgets('the tab bar track and the new-tab circle (titlebar.md)', (
    tester,
  ) async {
    await pump(tester);
    final bar = tester.getRect(find.byKey(const ValueKey('tab bar')));
    expect(bar.top, 32);
    expect(bar.height, 28);
    final plus = tester.getRect(find.byKey(const ValueKey('new tab')));
    expect(plus.size, const Size(30, 30));
    expect(800 - plus.right, 7);
    expect(plus.center.dy, bar.center.dy);
    final tab = tester.getRect(find.byKey(const ValueKey('tab 0')));
    expect(tab.left, closeTo(10, 0.01));
    expect(tab.right, closeTo(800 - 42, 0.01));
  });

  test('the selected tab keeps 120 pt while the others shrink', () {
    final widths = tabWidths(width: 300, weights: [1, 1, 1, 1], selected: 2);
    expect(widths[2], 120);
    expect(widths.reduce((a, b) => a + b), closeTo(300, 0.001));
    expect(widths[0], closeTo(60, 0.001));
    expect(tabWidths(width: 300, weights: [1, 1], selected: 0), [150, 150]);
    expect(tabWidths(width: 100, weights: [1], selected: 0), [100]);
  });

  test('the minimum window width keeps the traffic lights clear', () {
    expect(minimumWindowSize.width, 177);
    expect(minimumWindowWidth, 177);
  });
}
