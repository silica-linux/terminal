// Terminal, the terminal of Silica.

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:silica_ui/silica_ui.dart';

import 'src/l10n.dart';
import 'src/pty.dart';
import 'src/style.dart';
import 'src/window.dart';

void main(List<String> args) {
  final env = Platform.environment;
  // `-e program args…` runs a program instead of the login shell.
  final dash = args.indexOf('-e');
  final command = dash >= 0 && dash + 1 < args.length
      ? args.sublist(dash + 1)
      : null;
  final shell = env['SHELL'];
  final shellName = command?.first.split('/').last ?? shell?.split('/').last;
  WidgetsFlutterBinding.ensureInitialized();
  // The title band is part of the window: Ossido draws only the window buttons in it.
  SilicaWindow.setFullSizeContent(titleBarHeight).ignore();
  // 80 × 24 cells open a 597 × 421 pt window (terminal.md › Default size); the minimum keeps
  // 20 × 4 cells. Resizing does not snap to whole cells yet (docs/parity.md).
  SilicaWindow.setSizeLimits(min: minimumWindowSize).ignore();
  SilicaWindow.setSize(defaultWindowSize).ignore();
  runApp(
    AppLocalizationsScope(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: TerminalWindow(
          pty: SilicaPty(),
          command: command,
          cwd: env['HOME'],
          shellName: shellName,
          onLastTabClosed: () => SystemNavigator.pop(),
        ),
      ),
    ),
  );
}
