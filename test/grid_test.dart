import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal/src/grid.dart';
import 'package:terminal/src/pty.dart';

void main() {
  test('frames update only the rows they carry', () {
    final state = GridState();
    state.apply({
      'cols': 10,
      'rows': 3,
      'full': true,
      'lines': [
        {
          'y': 0,
          'runs': [
            ['hi', -1, -1, 0],
            ['red', 0xcd0000, -1, 1],
          ],
        },
      ],
      'cursor': {'x': 5, 'y': 0, 'visible': true, 'shape': 'block'},
      'modes': 3,
      'title': 'shell',
    });
    expect(state.text, 'hired\n\n');
    expect(state.lines[0].runs[1].bold, isTrue);
    expect(state.modes.appCursor, isTrue);
    expect(state.modes.bracketedPaste, isTrue);
    expect(state.title, 'shell');
    final first = state.lines[0];
    state.apply({
      'cols': 10,
      'rows': 3,
      'full': false,
      'lines': [
        {
          'y': 2,
          'runs': [
            [r'$ ', -1, -1, 0],
          ],
        },
      ],
    });
    expect(identical(state.lines[0], first), isTrue);
    expect(state.text, 'hired\n\n\$ ');
  });

  test('malformed frames are ignored, not thrown', () {
    final state = GridState();
    state.apply({
      'lines': [
        {'y': 99, 'runs': []},
        {'y': 'x'},
        'junk',
      ],
    });
    expect(state.lines, hasLength(24));
  });

  test(
    'rows with the same content share their key (scrolling reuses layout)',
    () {
      final a = GridRow(const [GridRun('ls', -1, -1, 0)]);
      final b = GridRow(const [GridRun('ls', -1, -1, 0)]);
      final c = GridRow(const [GridRun('ls', -1, -1, 1)]);
      expect(a.key, b.key);
      expect(a.key, isNot(c.key));
    },
  );

  testWidgets('the view spawns a grid session and writes typed keys', (
    tester,
  ) async {
    final pty = FakePty();
    final session = GridSession(pty: pty);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 140,
            height: 140,
            child: GridTerminalView(
              session: session,
              palette: const GridPalette(
                foreground: Color(0xff000000),
                background: Color(0xffffffff),
                cursor: Color(0xff888888),
              ),
              textStyle: const TextStyle(fontSize: 11.6),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(pty.calls.first.$1, 'spawn');
    expect(pty.sizes[1], (10, 20));
    pty.grid(1, {
      'cols': 20,
      'rows': 10,
      'full': true,
      'lines': [
        {
          'y': 0,
          'runs': [
            ['\$ ', -1, -1, 0],
          ],
        },
      ],
      'cursor': {'x': 2, 'y': 0, 'visible': true, 'shape': 'block'},
      'modes': 0,
    });
    await tester.pump();
    expect(session.state.text.startsWith('\$ '), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();
    expect(pty.written[1], [0x7f]);
    session.dispose();
  });
}
