// Tests measure with the real fonts: Inter for the interface (from silica_ui) and the bundled
// JetBrains Mono for the grid, so cell metrics and grid sizes are the app's.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final inter = FontLoader('packages/silica_ui/Inter')
    ..addFont(rootBundle.load('packages/silica_ui/fonts/Inter-Regular.ttf'))
    ..addFont(rootBundle.load('packages/silica_ui/fonts/Inter-SemiBold.ttf'));
  await inter.load();
  final mono = FontLoader('JetBrains Mono')
    ..addFont(rootBundle.load('fonts/JetBrainsMonoNL-Regular.ttf'))
    ..addFont(rootBundle.load('fonts/JetBrainsMonoNL-Bold.ttf'));
  await mono.load();
  await testMain();
}
