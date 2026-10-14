import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal/src/l10n.dart';
import 'package:terminal/src/pty.dart';
import 'package:terminal/src/session.dart';
import 'package:xterm/xterm.dart' show TerminalKey;

String screen(TerminalSession s) => [
  for (var y = 0; y < s.terminal.buffer.height; y++)
    s.terminal.buffer.lines[y].getText().trimRight(),
].join('\n').trimRight();

void main() {
  setUp(() => useLocale(const Locale('en')));

  test('spawns with the emulator size and shows the output', () async {
    final pty = FakePty();
    final s = TerminalSession(pty: pty, shellName: 'bash');
    await s.start();
    expect(s.id, 1);
    expect(pty.sizes[1], (24, 80));
    pty.output(1, 'hello\r\nworld');
    expect(screen(s), 'hello\nworld');
    expect(s.title, 'bash');
  });

  test('a UTF-8 character split across two messages arrives whole', () async {
    final pty = FakePty();
    final s = TerminalSession(pty: pty);
    await s.start();
    final bytes = utf8.encode('perché');
    pty.outputBytes(1, bytes.sublist(0, bytes.length - 1));
    pty.outputBytes(1, bytes.sublist(bytes.length - 1));
    expect(screen(s), 'perché');
  });

  test(
    'keys go to the process; a resize reaches the pseudo-terminal',
    () async {
      final pty = FakePty();
      final s = TerminalSession(pty: pty);
      await s.start();
      s.terminal.textInput('ls -l');
      s.terminal.keyInput(TerminalKey.enter);
      expect(utf8.decode(pty.written[1]!), 'ls -l\r');
      s.terminal.resize(100, 30);
      expect(pty.sizes[1], (30, 100));
    },
  );

  test('escape sequences: colours, alternate screen, title', () async {
    final pty = FakePty();
    final s = TerminalSession(pty: pty, shellName: 'zsh');
    await s.start();
    pty.output(1, '\x1b[31mred\x1b[0m \x1b[38;2;1;2;3mtrue\x1b[0m');
    expect(screen(s), 'red true');
    final cell = s.terminal.buffer.lines[0].getForeground(0);
    expect(cell, isNot(0));
    pty.output(1, '\x1b[?1049h');
    expect(s.terminal.isUsingAltBuffer, isTrue);
    pty.output(1, '\x1b[?1049l');
    expect(s.terminal.isUsingAltBuffer, isFalse);
    pty.output(1, '\x1b]0;~/src — vim\x07');
    expect(s.title, '~/src — vim');
  });

  test('exit: a closing line, then no more input', () async {
    final pty = FakePty();
    final s = TerminalSession(pty: pty);
    await s.start();
    pty.exit(1, code: 3);
    expect(s.ended, isTrue);
    expect(screen(s), contains(l10n.processExited(3)));
    s.terminal.textInput('x');
    expect(pty.written[1], isEmpty);
    s.dispose();
    expect(pty.calls.where((c) => c.$1 == 'close'), isEmpty);
  });

  test('outside Silica: a clear message instead of a shell', () async {
    final pty = FakePty()..spawnError = const PtyUnavailable();
    final s = TerminalSession(pty: pty);
    await s.start();
    expect(s.ended, isTrue);
    expect(s.error, isA<PtyUnavailable>());
    expect(screen(s).replaceAll('\n', ''), contains('Silica desktop'));
  });

  test('closing a running session closes its pseudo-terminal', () async {
    final pty = FakePty();
    final s = TerminalSession(pty: pty);
    await s.start();
    s.interrupt();
    s.dispose();
    expect(pty.calls.map((c) => c.$1), ['spawn', 'signal', 'close']);
  });
}
