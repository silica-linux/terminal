import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal/src/keys.dart';

KeyDownEvent down(LogicalKeyboardKey key, {String? character}) => KeyDownEvent(
  physicalKey: PhysicalKeyboardKey.keyA,
  logicalKey: key,
  character: character,
  timeStamp: Duration.zero,
);

String? encode(
  LogicalKeyboardKey key, {
  String? character,
  bool shift = false,
  bool alt = false,
  bool control = false,
  bool meta = false,
  int modes = 0,
  bool optionAsMeta = false,
}) => encodeKey(
  down(key, character: character),
  shift: shift,
  alt: alt,
  control: control,
  meta: meta,
  modes: TerminalModes(modes),
  optionAsMeta: optionAsMeta,
);

void main() {
  test('Backspace is DEL, Ctrl+Backspace is BS', () {
    expect(encode(LogicalKeyboardKey.backspace), '\x7f');
    expect(encode(LogicalKeyboardKey.backspace, control: true), '\b');
  });

  test('a held key repeats the same bytes', () {
    final repeat = KeyRepeatEvent(
      physicalKey: PhysicalKeyboardKey.backspace,
      logicalKey: LogicalKeyboardKey.backspace,
      timeStamp: Duration.zero,
    );
    expect(
      encodeKey(repeat, shift: false, alt: false, control: false, meta: false),
      '\x7f',
    );
  });

  test('Ctrl+letters and punctuation are C0 controls', () {
    expect(
      encode(LogicalKeyboardKey.keyC, character: 'c', control: true),
      '\x03',
    );
    expect(
      encode(LogicalKeyboardKey.keyD, character: 'd', control: true),
      '\x04',
    );
    expect(
      encode(LogicalKeyboardKey.space, character: ' ', control: true),
      '\x00',
    );
    expect(encode(LogicalKeyboardKey.bracketLeft, control: true), '\x1b');
    expect(encode(LogicalKeyboardKey.backslash, control: true), '\x1c');
  });

  test('cursor keys follow DECCKM and carry modifiers', () {
    expect(encode(LogicalKeyboardKey.arrowUp), '\x1b[A');
    expect(encode(LogicalKeyboardKey.arrowUp, modes: 1), '\x1bOA');
    expect(encode(LogicalKeyboardKey.arrowLeft, shift: true), '\x1b[1;2D');
    expect(encode(LogicalKeyboardKey.arrowRight, control: true), '\x1b[1;5C');
    expect(encode(LogicalKeyboardKey.home), '\x1b[H');
    expect(encode(LogicalKeyboardKey.end, modes: 1), '\x1bOF');
  });

  test('editing and function keys', () {
    expect(encode(LogicalKeyboardKey.pageUp), '\x1b[5~');
    expect(encode(LogicalKeyboardKey.pageDown, shift: true), '\x1b[6;2~');
    expect(encode(LogicalKeyboardKey.delete), '\x1b[3~');
    expect(encode(LogicalKeyboardKey.f1), '\x1bOP');
    expect(encode(LogicalKeyboardKey.f5), '\x1b[15~');
    expect(encode(LogicalKeyboardKey.f12, control: true), '\x1b[24;5~');
    expect(encode(LogicalKeyboardKey.tab, shift: true), '\x1b[Z');
    expect(encode(LogicalKeyboardKey.enter), '\r');
    expect(encode(LogicalKeyboardKey.escape), '\x1b');
  });

  test('Option as Meta prefixes ESC only when enabled', () {
    expect(encode(LogicalKeyboardKey.keyB, character: 'b', alt: true), 'b');
    expect(
      encode(
        LogicalKeyboardKey.keyB,
        character: 'b',
        alt: true,
        optionAsMeta: true,
      ),
      '\x1bb',
    );
  });

  test('Command shortcuts and lone modifiers are not sent', () {
    expect(encode(LogicalKeyboardKey.keyC, character: 'c', meta: true), isNull);
    expect(encode(LogicalKeyboardKey.shiftLeft), isNull);
  });

  test('bracketed paste wraps the text and cannot be closed from inside', () {
    expect(encodePaste('a\nb', TerminalModes.none), 'a\rb');
    expect(
      encodePaste('x\x1b[201~y', const TerminalModes(2)),
      '\x1b[200~xy\x1b[201~',
    );
  });
}
