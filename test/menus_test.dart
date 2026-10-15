import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silica_ui/silica_ui.dart';
import 'package:terminal/src/l10n.dart';
import 'package:terminal/src/pty.dart';
import 'package:terminal/src/window.dart';

typedef Json = Map<String, Object?>;

void main() {
  Future<TerminalWindowState> pump(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
  }) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      AppLocalizationsScope(
        locale: locale,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: TerminalWindow(pty: FakePty(), shellName: 'bash'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    return tester.state<TerminalWindowState>(find.byType(TerminalWindow));
  }

  SilicaMenuDelegate delegate() =>
      WidgetsBinding.instance.platformMenuDelegate as SilicaMenuDelegate;

  List<Json> menus() => (delegate().lastModel!['menus']! as List).cast<Json>();

  Json menu(String label) => menus().firstWhere((m) => m['label'] == label);

  /// The entry with this label in a menu, searching submenus.
  Json? entry(List<Object?> items, String label) {
    // Standard items carry a role and no label: the bar labels them.
    const roles = {
      'Undo': 'undo',
      'Redo': 'redo',
      'Cut': 'cut',
      'Copy': 'copy',
      'Paste': 'paste',
      'Select All': 'select_all',
    };
    for (final e in items.cast<Json>()) {
      if (e['label'] == label ||
          (e['role'] != null && e['role'] == roles[label])) {
        return e;
      }
      final sub = e['items'];
      if (sub is List) {
        final found = entry(sub, label);
        if (found != null) return found;
      }
    }
    return null;
  }

  Json item(String menuLabel, String label) {
    final found = entry(menu(menuLabel)['items']! as List, label);
    expect(found, isNotNull, reason: '$menuLabel › $label');
    return found!;
  }

  bool enabled(Json e) => e['enabled'] == true;

  void choose(Json e) => expect(delegate().activate(e['id']! as int), isTrue);

  testWidgets('the menu bar has the six menus of the reference', (
    tester,
  ) async {
    await pump(tester);
    expect(
      [for (final m in menus()) m['label']],
      ['Terminal', 'Shell', 'Edit', 'View', 'Window', 'Help'],
    );
    expect(menus().first['role'], 'app');
    expect(menu('Window')['role'], 'window');
    expect(menu('Help')['role'], 'help');
    // The system items of the app menu are the bar's.
    final app = (menus().first['items']! as List).cast<Json>();
    expect(
      [for (final e in app) e['role']].whereType<String>(),
      containsAll(['services', 'hide', 'hide_others', 'show_all', 'quit']),
    );
  });

  testWidgets('Shell: shortcuts, separators and enabled states', (
    tester,
  ) async {
    await pump(tester);
    final newTab = item('Shell', 'New Tab with Profile - Basic');
    expect(enabled(newTab), isTrue);
    expect(newTab['shortcut'], {'key': 'T', 'meta': true});
    expect(item('Shell', 'New Tab with Same Command')['shortcut'], {
      'key': 'T',
      'meta': true,
      'ctrl': true,
    });
    // Not built yet: shown, disabled.
    final window = item('Shell', 'New Window');
    expect(window['enabled'], isFalse);
    for (final label in [
      'New Command…',
      'New Remote Connection…',
      'Open…',
      'Close All',
      'Export Text As…',
      'Show Inspector',
      'Edit Title',
      'Reset',
      'Print…',
    ]) {
      expect(enabled(item('Shell', label)), isFalse, reason: label);
    }
    expect(item('Shell', 'Close Window')['shortcut'], {
      'key': 'W',
      'meta': true,
    });
    expect(
      (menu('Shell')['items']! as List).whereType<Json>().where(
        (e) => e['separator'] == true,
      ),
      isNotEmpty,
    );
  });

  testWidgets('Shell › New Tab opens a tab; Close Tab closes it', (
    tester,
  ) async {
    final state = await pump(tester);
    expect(state.tabs, hasLength(1));
    choose(item('Shell', 'New Tab with Profile - Basic'));
    await tester.pump();
    expect(state.tabs, hasLength(2));
    choose(item('Shell', 'New Tab with Same Command'));
    await tester.pump();
    expect(state.tabs, hasLength(3));
    await tester.pump(const Duration(seconds: 1));
    // With several tabs the item closes the tab.
    final close = item('Shell', 'Close Tab');
    choose(close);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(state.tabs, hasLength(2));
  });

  testWidgets('Edit: Copy follows the selection, Paste and Select All work', (
    tester,
  ) async {
    final state = await pump(tester);
    expect(enabled(item('Edit', 'Undo')), isFalse);
    expect(enabled(item('Edit', 'Redo')), isFalse);
    expect(enabled(item('Edit', 'Cut')), isFalse);
    expect(enabled(item('Edit', 'Copy')), isFalse);
    expect(item('Edit', 'Copy')['shortcut'], {'key': 'C', 'meta': true});
    expect(item('Edit', 'Paste')['shortcut'], {'key': 'V', 'meta': true});
    expect(item('Edit', 'Select All')['shortcut'], {'key': 'A', 'meta': true});
    expect(enabled(item('Edit', 'Paste')), isTrue);
    expect(enabled(item('Edit', 'Select All')), isTrue);
    expect(enabled(item('Edit', 'Copy Special')), isTrue);
    expect(enabled(item('Edit', 'Paste Escaped Text')), isFalse);
    expect(item('Edit', 'Terminal Settings (default)')['checked'], isTrue);

    choose(item('Edit', 'Select All'));
    await tester.pump();
    expect(state.session.controller.selection, isNotNull);
    expect(enabled(item('Edit', 'Copy')), isTrue);

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
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    state.session.terminal.write('menu copy');
    choose(item('Edit', 'Copy'));
    await tester.pump();
    expect(copied, contains('menu copy'));
  });

  testWidgets('Edit › Find: opens the bar, next and previous follow it', (
    tester,
  ) async {
    final state = await pump(tester);
    state.session.terminal.write('one two one\r\n');
    await tester.pump();
    final findItem = item('Edit', 'Find…');
    expect(findItem['shortcut'], {'key': 'F', 'meta': true});
    expect(enabled(item('Edit', 'Find Next')), isFalse);
    expect(enabled(item('Edit', 'Hide Find Bar')), isFalse);
    choose(findItem);
    await tester.pump();
    expect(find.byKey(const ValueKey('find bar')), findsOneWidget);
    expect(enabled(item('Edit', 'Hide Find Bar')), isTrue);
    await tester.enterText(find.byKey(const ValueKey('find field')), 'one');
    await tester.pump();
    expect(find.text('2 of 2'), findsOneWidget);
    expect(item('Edit', 'Find Next')['shortcut'], {'key': 'G', 'meta': true});
    choose(item('Edit', 'Find Previous'));
    await tester.pump();
    expect(find.text('1 of 2'), findsOneWidget);
    choose(item('Edit', 'Hide Find Bar'));
    await tester.pump();
    expect(find.byKey(const ValueKey('find bar')), findsNothing);
  });

  testWidgets('View: scroll items act on the scrollback; the rest is off', (
    tester,
  ) async {
    final state = await pump(tester);
    for (var i = 0; i < 200; i++) {
      state.session.terminal.write('line $i\r\n');
    }
    await tester.pump();
    await tester.pump();
    final scroll = tester.widget<Scrollable>(find.byType(Scrollable).first);
    final position = scroll.controller!.position;
    expect(item('View', 'Scroll to Top')['shortcut'], {
      'key': 'Home',
      'meta': true,
    });
    choose(item('View', 'Scroll to Top'));
    await tester.pump();
    expect(position.pixels, position.minScrollExtent);
    choose(item('View', 'Page Down'));
    await tester.pump();
    expect(position.pixels, closeTo(position.viewportDimension, 1));
    choose(item('View', 'Line Down'));
    await tester.pump();
    expect(position.pixels, closeTo(position.viewportDimension + 14, 1));
    choose(item('View', 'Scroll to Bottom'));
    await tester.pump();
    expect(position.pixels, position.maxScrollExtent);
    for (final label in [
      'Show All Tabs',
      'Split Pane',
      'Close Split Pane',
      'Default Font Size',
      'Bigger',
      'Smaller',
      'Show Alternate Screen',
    ]) {
      expect(enabled(item('View', label)), isFalse, reason: label);
    }
    expect(item('View', 'Allow Mouse Reporting')['checked'], isTrue);
    expect(entry(menu('View')['items']! as List, 'Bigger')!['shortcut'], {
      'key': '+',
      'meta': true,
    });
  });

  testWidgets('Window: tab switching needs two tabs', (tester) async {
    final state = await pump(tester);
    expect(enabled(item('Window', 'Show Next Tab')), isFalse);
    expect(item('Window', 'Show Next Tab')['shortcut'], {
      'key': 'Tab',
      'ctrl': true,
    });
    state.newTab();
    await tester.pump();
    expect(state.current, 1);
    expect(enabled(item('Window', 'Show Previous Tab')), isTrue);
    expect(item('Window', 'Show Previous Tab')['shortcut'], {
      'key': 'Tab',
      'ctrl': true,
      'shift': true,
    });
    choose(item('Window', 'Show Previous Tab'));
    await tester.pump();
    expect(state.current, 0);
    choose(item('Window', 'Show Next Tab'));
    await tester.pump();
    expect(state.current, 1);
    expect(enabled(item('Window', 'Move Tab to New Window')), isFalse);
    expect(enabled(item('Window', 'Merge All Windows')), isFalse);
  });

  testWidgets('⌘ shortcuts run the menu items, also inside the grid', (
    tester,
  ) async {
    final state = await pump(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyT);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await tester.pump();
    expect(state.tabs, hasLength(2));
  });

  testWidgets('in Italian the menus speak Italian', (tester) async {
    await pump(tester, locale: const Locale('it'));
    expect(
      [for (final m in menus()) m['label']],
      ['Terminale', 'Shell', 'Modifica', 'Vista', 'Finestra', 'Aiuto'],
    );
    expect(
      enabled(item('Shell', 'Nuovo pannello con profilo - Basic')),
      isTrue,
    );
    expect(enabled(item('Modifica', 'Trova…')), isTrue);
  });
}
