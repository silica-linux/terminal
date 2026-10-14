// Geometry and colours of the window and of the two default profiles.
//
// PROVISIONAL: everything here waits for the measurements of silica-reference#75 (TE-01,
// `terminal.md`). The values are our own starting points, not observed ones; docs/parity.md
// lists them as provisional until the measurements replace them.

import 'package:flutter/widgets.dart';
import 'package:xterm/xterm.dart';

/// The title band at the top (the window buttons of Ossido sit in it). Provisional.
const double titleBarHeight = 32;

/// The tab bar under the title band, shown from two tabs. Provisional.
const double tabBarHeight = 26;

/// Space around the character grid. Provisional.
const EdgeInsets gridPadding = EdgeInsets.fromLTRB(6, 4, 6, 4);

/// The terminal font: JetBrains Mono (OFL 1.1, bundled), 12 pt, line height 1.2. Provisional.
const TerminalStyle terminalStyle = TerminalStyle(
  fontFamily: 'JetBrains Mono',
  fontSize: 12,
  height: 1.2,
  fontFamilyFallback: ['Noto Sans Mono', 'DejaVu Sans Mono', 'monospace'],
);

/// Default size in cells, for the first window. Provisional.
const int defaultColumns = 80;
const int defaultRows = 24;

/// A profile: the terminal colours plus the window chrome around them.
@immutable
class Profile {
  const Profile({
    required this.theme,
    required this.chrome,
    required this.title,
    required this.titleInactive,
    required this.tab,
    required this.tabActive,
    required this.tabText,
  });

  final TerminalTheme theme;
  final Color chrome;
  final Color title;
  final Color titleInactive;
  final Color tab;
  final Color tabActive;
  final Color tabText;
}

/// The ANSI palette shared by both profiles (our own values). Provisional.
const _ansi = (
  black: Color(0xFF1D1F21),
  red: Color(0xFFC8423C),
  green: Color(0xFF3F9A3F),
  yellow: Color(0xFFB8901C),
  blue: Color(0xFF3368CF),
  magenta: Color(0xFFA34CB4),
  cyan: Color(0xFF2E9AA5),
  white: Color(0xFFC9CCCE),
  brightBlack: Color(0xFF6B6F73),
  brightRed: Color(0xFFEE6560),
  brightGreen: Color(0xFF5FC45C),
  brightYellow: Color(0xFFE2BA3F),
  brightBlue: Color(0xFF5E91F0),
  brightMagenta: Color(0xFFC977D6),
  brightCyan: Color(0xFF51C3CC),
  brightWhite: Color(0xFFF4F5F6),
);

/// Dark text on a light background, for the light appearance. Provisional.
const Profile lightProfile = Profile(
  theme: TerminalTheme(
    cursor: Color(0xFF6B6F73),
    selection: Color(0x553368CF),
    foreground: Color(0xFF1D1D1F),
    background: Color(0xFFFFFFFF),
    black: Color(0xFF1D1F21),
    red: Color(0xFFB8322C),
    green: Color(0xFF2F7F2F),
    yellow: Color(0xFF8F6C0C),
    blue: Color(0xFF2858BF),
    magenta: Color(0xFF8E3C9F),
    cyan: Color(0xFF1E7F8A),
    white: Color(0xFFB9BCBE),
    brightBlack: Color(0xFF5B5F63),
    brightRed: Color(0xFFD9504A),
    brightGreen: Color(0xFF3F9A3F),
    brightYellow: Color(0xFFB8901C),
    brightBlue: Color(0xFF3368CF),
    brightMagenta: Color(0xFFA34CB4),
    brightCyan: Color(0xFF2E9AA5),
    brightWhite: Color(0xFF8A8D90),
    searchHitBackground: Color(0xFFFFE38A),
    searchHitBackgroundCurrent: Color(0xFFFFB648),
    searchHitForeground: Color(0xFF1D1D1F),
  ),
  chrome: Color(0xFFF6F6F6),
  title: Color(0xFF4D4D4D),
  titleInactive: Color(0xFFBEBEBE),
  tab: Color(0xFFE8E8E8),
  tabActive: Color(0xFFFEFDFE),
  tabText: Color(0xFF4C4B4C),
);

/// Light text on a dark background, for the dark appearance. Provisional.
final Profile darkProfile = Profile(
  theme: TerminalTheme(
    cursor: const Color(0xFFC9CCCE),
    selection: const Color(0x665E91F0),
    foreground: const Color(0xFFE9E9E9),
    background: const Color(0xFF1E1E1E),
    black: _ansi.black,
    red: _ansi.red,
    green: _ansi.green,
    yellow: _ansi.yellow,
    blue: _ansi.blue,
    magenta: _ansi.magenta,
    cyan: _ansi.cyan,
    white: _ansi.white,
    brightBlack: _ansi.brightBlack,
    brightRed: _ansi.brightRed,
    brightGreen: _ansi.brightGreen,
    brightYellow: _ansi.brightYellow,
    brightBlue: _ansi.brightBlue,
    brightMagenta: _ansi.brightMagenta,
    brightCyan: _ansi.brightCyan,
    brightWhite: _ansi.brightWhite,
    searchHitBackground: const Color(0xFF8A6D1E),
    searchHitBackgroundCurrent: const Color(0xFFC9871E),
    searchHitForeground: const Color(0xFFFFFFFF),
  ),
  chrome: const Color(0xFF2B2B2B),
  title: const Color(0xFFE9E9E9),
  titleInactive: const Color(0xFF646464),
  tab: const Color(0xFF404041),
  tabActive: const Color(0xFF464648),
  tabText: const Color(0xFFECECEC),
);

/// The profile for the system appearance.
Profile profileOf(BuildContext context) =>
    MediaQuery.maybePlatformBrightnessOf(context) == Brightness.dark
    ? darkProfile
    : lightProfile;
