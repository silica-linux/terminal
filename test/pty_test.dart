import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal/src/pty.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('events from the embedder: output, exit, malformed ones ignored', () {
    final out = SilicaPty.parseEvent('output', {
      'id': 3,
      'data': base64Encode(utf8.encode('hi')),
    });
    expect(out, isA<PtyOutput>());
    expect(utf8.decode((out! as PtyOutput).data), 'hi');
    expect(out.id, 3);
    final exit = SilicaPty.parseEvent('exit', {'id': 3, 'code': 2});
    expect((exit! as PtyExit).code, 2);
    expect((exit as PtyExit).signal, isNull);
    final killed = SilicaPty.parseEvent('exit', {'id': 3, 'signal': 9});
    expect((killed! as PtyExit).signal, 9);
    expect(SilicaPty.parseEvent('output', {'id': 3, 'data': '%%%'}), isNull);
    expect(SilicaPty.parseEvent('output', {'data': 'aGk='}), isNull);
    expect(SilicaPty.parseEvent('exit', 'nope'), isNull);
    expect(SilicaPty.parseEvent('other', {'id': 1}), isNull);
  });

  test('requests on silica/pty follow the protocol', () async {
    const channel = MethodChannel('silica/pty', JSONMethodCodec());
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return call.method == 'spawn' ? {'id': 7} : null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    final pty = SilicaPty(channel: channel);
    final id = await pty.spawn(rows: 24, cols: 80, cwd: '/tmp');
    expect(id, 7);
    await pty.write(7, Uint8List.fromList(utf8.encode('ls\r')));
    await pty.resize(7, rows: 30, cols: 100, pixelWidth: 800);
    await pty.signal(7, 'INT');
    await pty.close(7);
    expect(calls.map((c) => c.method), [
      'spawn',
      'write',
      'resize',
      'signal',
      'close',
    ]);
    expect(calls[0].arguments, {'cwd': '/tmp', 'rows': 24, 'cols': 80});
    expect(calls[1].arguments, {
      'id': 7,
      'data': base64Encode(utf8.encode('ls\r')),
    });
    expect(calls[2].arguments, {
      'id': 7,
      'rows': 30,
      'cols': 100,
      'pixelWidth': 800,
    });
    expect(calls[3].arguments, {'id': 7, 'signal': 'INT'});
  });

  test('outside Silica the channel is missing: PtyUnavailable', () async {
    final pty = SilicaPty(
      channel: const MethodChannel('silica/pty-missing', JSONMethodCodec()),
    );
    expect(() => pty.spawn(rows: 24, cols: 80), throwsA(isA<PtyUnavailable>()));
  });
}
