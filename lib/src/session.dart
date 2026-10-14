// One terminal session: the emulator (xterm.dart) wired to a pseudo-terminal of the embedder.
// Keystrokes go to the process as UTF-8; the process output is decoded as a UTF-8 stream (a
// character may be split across two messages) and fed to the emulator; a layout change resizes
// the pseudo-terminal; the title follows the escape sequences of the program.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:xterm/xterm.dart';

import 'l10n.dart';
import 'pty.dart';

/// Lines kept above the screen.
const int scrollbackLines = 10000;

class TerminalSession extends ChangeNotifier {
  TerminalSession({
    required this.pty,
    this.command,
    this.cwd,
    String? shellName,
  }) : _defaultTitle = shellName ?? 'sh' {
    terminal = Terminal(
      maxLines: scrollbackLines,
      onOutput: _send,
      onResize: _resized,
      onTitleChange: (title) {
        _title = title;
        notifyListeners();
      },
    );
  }

  final PtyBackend pty;

  /// The program to run; null: the user's login shell.
  final List<String>? command;
  final String? cwd;
  final String _defaultTitle;

  late final Terminal terminal;
  final TerminalController controller = TerminalController();

  int? _id;
  String? _title;
  StreamSubscription<PtyEvent>? _events;
  late final ByteConversionSink _decoder = const Utf8Decoder(
    allowMalformed: true,
  ).startChunkedConversion(_TextSink(terminal.write));

  /// The id of the pseudo-terminal, once spawned.
  int? get id => _id;

  /// The title set by the program, or the name of the shell.
  String get title => _title ?? _defaultTitle;

  /// The process has ended (or never started).
  bool get ended => _ended;
  bool _ended = false;

  /// Why the session could not start, if it could not: [PtyUnavailable] or another error.
  Object? get error => _error;
  Object? _error;

  /// Starts the process with the current size of the emulator.
  Future<void> start() async {
    _events = pty.events.listen(_event);
    try {
      _id = await pty.spawn(
        command: command,
        cwd: cwd,
        env: const {'TERM_PROGRAM': 'Silica Terminal'},
        rows: terminal.viewHeight,
        cols: terminal.viewWidth,
      );
    } on Object catch (error) {
      _error = error;
      _ended = true;
      terminal.write(
        error is PtyUnavailable
            ? '${l10n.noPty}\r\n'
            : '${l10n.spawnFailed('$error')}\r\n',
      );
      notifyListeners();
      return;
    }
    notifyListeners();
  }

  void _event(PtyEvent event) {
    if (event.id != _id) return;
    switch (event) {
      case PtyOutput(:final data):
        _decoder.add(data);
      case PtyExit(:final code, :final signal):
        _ended = true;
        final message = signal != null
            ? l10n.processKilled(signal)
            : l10n.processExited(code ?? 0);
        terminal.write('\r\n\x1b[2m$message\x1b[0m\r\n');
        notifyListeners();
      case PtyGrid():
        // Only grid sessions (spawn(grid: true)) receive rows.
        break;
    }
  }

  void _send(String data) {
    final id = _id;
    if (id == null || _ended) return;
    pty.write(id, Uint8List.fromList(utf8.encode(data))).ignore();
  }

  void _resized(int cols, int rows, int pixelWidth, int pixelHeight) {
    final id = _id;
    if (id == null || _ended) return;
    pty
        .resize(
          id,
          rows: rows,
          cols: cols,
          pixelWidth: pixelWidth,
          pixelHeight: pixelHeight,
        )
        .ignore();
    notifyListeners();
  }

  /// A program other than the shell runs in the foreground (closing would terminate it).
  Future<bool> hasForegroundProcess() async {
    final id = _id;
    if (id == null || _ended) return false;
    return pty.hasForegroundProcess(id);
  }

  /// Sends Ctrl-C's signal to the process.
  void interrupt() {
    final id = _id;
    if (id != null && !_ended) pty.signal(id, 'INT').ignore();
  }

  @override
  void dispose() {
    _events?.cancel();
    final id = _id;
    if (id != null && !_ended) pty.close(id).ignore();
    controller.dispose();
    super.dispose();
  }
}

class _TextSink implements Sink<String> {
  _TextSink(this.write);
  final void Function(String) write;

  @override
  void add(String data) {
    if (data.isNotEmpty) write(data);
  }

  @override
  void close() {}
}
