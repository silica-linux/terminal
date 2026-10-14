// The pseudo-terminal of the Silica embedder: channel `silica/pty` (JSONMethodCodec). The app
// has no native code; the embedder spawns the shell on a PTY and streams its output.
//
// app → embedder: `spawn {command?, cwd?, env?, rows, cols}` → `{id}`; `write {id, data}`
// (base64); `resize {id, rows, cols, pixelWidth?, pixelHeight?}`; `signal {id, signal}`
// ("INT", "TERM", "HUP", "KILL"); `close {id}`.
// embedder → app: `output {id, data}` (base64), `exit {id, code?, signal?}`.
// With `spawn {grid: true}` the embedder emulates the terminal and sends `grid {id, cols, rows,
// full, lines: [{y, runs: [[text, fg, bg, flags]…]}], cursor, modes, title?}` instead of bytes.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Something that happened to a pseudo-terminal.
@immutable
sealed class PtyEvent {
  const PtyEvent(this.id);
  final int id;
}

/// Bytes written by the process.
class PtyOutput extends PtyEvent {
  const PtyOutput(super.id, this.data);
  final Uint8List data;
}

/// The rows of an emulated terminal that changed (`spawn(grid: true)`), as sent by the
/// embedder: the raw message map, decoded by `GridState.apply`.
class PtyGrid extends PtyEvent {
  const PtyGrid(super.id, this.frame);
  final Map<Object?, Object?> frame;
}

/// The process ended: with an exit `code`, or killed by `signal`.
class PtyExit extends PtyEvent {
  const PtyExit(super.id, {this.code, this.signal});
  final int? code;
  final int? signal;
}

/// The pseudo-terminal service is missing (the app runs outside Silica).
class PtyUnavailable implements Exception {
  const PtyUnavailable();
  @override
  String toString() => 'the silica/pty channel is not available';
}

/// The pseudo-terminals of the app: real ones on the embedder, fake ones in tests.
abstract class PtyBackend {
  /// Starts `command` (null: the user's login shell) on a new pseudo-terminal of `rows` ×
  /// `cols` cells and returns its id. Throws [PtyUnavailable] outside Silica.
  Future<int> spawn({
    List<String>? command,
    String? cwd,
    Map<String, String>? env,
    required int rows,
    required int cols,
    bool grid = false,
  });

  Future<void> write(int id, Uint8List data);

  Future<void> resize(
    int id, {
    required int rows,
    required int cols,
    int? pixelWidth,
    int? pixelHeight,
  });

  /// One of "INT", "TERM", "HUP", "KILL".
  Future<void> signal(int id, String signal);

  Future<void> close(int id);

  /// A process other than the shell runs in the foreground of the pseudo-terminal `id`.
  Future<bool> hasForegroundProcess(int id);

  /// Output and exits of every pseudo-terminal.
  Stream<PtyEvent> get events;
}

/// The embedder's `silica/pty` channel.
class SilicaPty implements PtyBackend {
  SilicaPty({MethodChannel? channel})
    : _channel =
          channel ?? const MethodChannel('silica/pty', JSONMethodCodec()) {
    _channel.setMethodCallHandler(_handle);
  }

  final MethodChannel _channel;
  final StreamController<PtyEvent> _events = StreamController.broadcast();

  @override
  Stream<PtyEvent> get events => _events.stream;

  Future<Object?> _handle(MethodCall call) async {
    final event = parseEvent(call.method, call.arguments);
    if (event != null) _events.add(event);
    return null;
  }

  /// An event from a call of the embedder; null if it is not one (or is malformed).
  static PtyEvent? parseEvent(String method, Object? args) {
    if (args is! Map) return null;
    final id = args['id'];
    if (id is! int) return null;
    switch (method) {
      case 'output':
        final data = args['data'];
        if (data is! String) return null;
        try {
          return PtyOutput(id, base64Decode(data));
        } on FormatException {
          return null;
        }
      case 'grid':
        return PtyGrid(id, args);
      case 'exit':
        final code = args['code'];
        final signal = args['signal'];
        return PtyExit(
          id,
          code: code is int ? code : null,
          signal: signal is int ? signal : null,
        );
    }
    return null;
  }

  Future<Object?> _invoke(String method, Map<String, Object?> args) async {
    try {
      return await _channel.invokeMethod<Object?>(method, args);
    } on MissingPluginException {
      throw const PtyUnavailable();
    }
  }

  @override
  Future<int> spawn({
    List<String>? command,
    String? cwd,
    Map<String, String>? env,
    required int rows,
    required int cols,
    bool grid = false,
  }) async {
    final reply = await _invoke('spawn', {
      'command': ?command,
      'cwd': ?cwd,
      'env': ?env,
      'rows': rows,
      'cols': cols,
      if (grid) 'grid': true,
    });
    final id = reply is Map ? reply['id'] : null;
    if (id is! int) {
      throw PlatformException(code: 'spawn', message: 'no id in $reply');
    }
    return id;
  }

  @override
  Future<void> write(int id, Uint8List data) =>
      _invoke('write', {'id': id, 'data': base64Encode(data)});

  @override
  Future<void> resize(
    int id, {
    required int rows,
    required int cols,
    int? pixelWidth,
    int? pixelHeight,
  }) => _invoke('resize', {
    'id': id,
    'rows': rows,
    'cols': cols,
    'pixelWidth': ?pixelWidth,
    'pixelHeight': ?pixelHeight,
  });

  @override
  Future<void> signal(int id, String signal) =>
      _invoke('signal', {'id': id, 'signal': signal});

  @override
  Future<void> close(int id) => _invoke('close', {'id': id});

  // provisional: the `busy` request is not in the embedder protocol yet; without it no tab
  // counts as busy and closing never asks.
  @override
  Future<bool> hasForegroundProcess(int id) async {
    try {
      return await _invoke('busy', {'id': id}) == true;
    } on Object {
      return false;
    }
  }
}

/// A pseudo-terminal backend in memory, for tests: records what the app does and lets the
/// test play the process.
class FakePty implements PtyBackend {
  final StreamController<PtyEvent> _events = StreamController.broadcast(
    sync: true,
  );
  int _next = 1;

  /// Every spawn, write, resize, signal and close, as `(method, id, details)`.
  final List<(String, int, Object?)> calls = [];

  /// Bytes the app wrote to each pseudo-terminal.
  final Map<int, List<int>> written = {};

  /// The last size of each pseudo-terminal, `(rows, cols)`.
  final Map<int, (int, int)> sizes = {};

  /// Throw this from [spawn] (e.g. [PtyUnavailable]).
  Object? spawnError;

  @override
  Stream<PtyEvent> get events => _events.stream;

  @override
  Future<int> spawn({
    List<String>? command,
    String? cwd,
    Map<String, String>? env,
    required int rows,
    required int cols,
    bool grid = false,
  }) async {
    final error = spawnError;
    if (error != null) throw error;
    final id = _next++;
    calls.add(('spawn', id, command));
    sizes[id] = (rows, cols);
    written[id] = [];
    return id;
  }

  @override
  Future<void> write(int id, Uint8List data) async {
    calls.add(('write', id, data));
    written.putIfAbsent(id, () => []).addAll(data);
  }

  @override
  Future<void> resize(
    int id, {
    required int rows,
    required int cols,
    int? pixelWidth,
    int? pixelHeight,
  }) async {
    calls.add(('resize', id, (rows, cols)));
    sizes[id] = (rows, cols);
  }

  @override
  Future<void> signal(int id, String signal) async =>
      calls.add(('signal', id, signal));

  @override
  Future<void> close(int id) async => calls.add(('close', id, null));

  /// Ids whose shell has a foreground program (vim, a build, ...).
  final Set<int> busy = {};

  @override
  Future<bool> hasForegroundProcess(int id) async => busy.contains(id);

  /// The process of `id` prints `text`.
  void output(int id, String text) =>
      _events.add(PtyOutput(id, Uint8List.fromList(utf8.encode(text))));

  /// The process of `id` prints raw `bytes` (e.g. half of a UTF-8 sequence).
  void outputBytes(int id, List<int> bytes) =>
      _events.add(PtyOutput(id, Uint8List.fromList(bytes)));

  /// The embedder sends a grid frame for `id`.
  void grid(int id, Map<String, Object?> frame) =>
      _events.add(PtyGrid(id, {'id': id, ...frame}));

  /// The process of `id` exits.
  void exit(int id, {int? code, int? signal}) =>
      _events.add(PtyExit(id, code: code, signal: signal));
}
