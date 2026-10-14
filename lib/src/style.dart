// Geometry and colours of the window and of the profiles, from the measurements of TE-01
// (silica-reference#75, `terminal.md`): 1 pt = 1 px, window origin at its top-left corner.
// Values not measured are marked "estimated"; docs/parity.md lists both.

import 'package:flutter/widgets.dart';
import 'package:xterm/xterm.dart';

/// The title band at the top: Ossido puts the window buttons in it (AX 16 × 16 at y +8).
const double titleBarHeight = 32;

/// The tab bar under the title band: always visible, even with one tab (AX 28 pt at y +32).
const double tabBarHeight = 28;

/// A tab: a capsule 24 pt tall, 2 pt below the top of the bar, starting at x +10.
const double tabHeight = 24;
const double tabTop = 2;
const double tabBarLeft = 10;

/// The new-tab button: a 30 × 30 circle at (+560, +31) in an 80-column window, so its right
/// edge is 7 pt from the window's.
const double newTabSide = 30;
const double newTabRight = 7;
const double newTabTop = -1;

/// A new tab slides in from the right and settles in ~550 ms; a closed one shrinks away in
/// ~500 ms.
const Duration tabEnter = Duration(milliseconds: 550);
const Duration tabExit = Duration(milliseconds: 500);

/// The content area starts at window y +68 (title band + tab bar), under a 1 pt separator.
const double chromeHeight = titleBarHeight + tabBarHeight + 8;

/// Text insets around the character grid: left 10, top 7, bottom 10; right 27 = 8 + the
/// 19 pt scroller column.
const EdgeInsets gridPadding = EdgeInsets.fromLTRB(10, 7, 27, 10);

/// The scroller column at the right of the grid and its knob.
const double scrollerWidth = 19;
const double scrollerKnobWidth = 11;

/// The find bar, inserted under the tab bar: 32 pt; the window grows by as much.
const double findBarHeight = 32;
const Size findFieldSize = Size(482, 22);
const double findFieldLeft = 7;

/// A cell is 7 × 14 pt. The bundled JetBrains Mono NL advances 0.6 em, so 7 pt needs
/// 7 / 0.6 = 11.667 pt; a line height of 14 pt is 1.2 em. Residual against 7 × 14: < 0.01 pt.
const Size cellSize = Size(7, 14);
const double terminalFontSize = 7 / 0.6;

/// The terminal font: JetBrains Mono NL (OFL 1.1, bundled).
const TerminalStyle terminalStyle = TerminalStyle(
  fontFamily: 'JetBrains Mono',
  fontSize: terminalFontSize,
  height: 14 / terminalFontSize,
  fontFamilyFallback: ['Noto Sans Mono', 'DejaVu Sans Mono', 'monospace'],
);

/// The default window: 80 × 24 cells.
const int defaultColumns = 80;
const int defaultRows = 24;

/// The smallest window we allow: 20 × 4 cells (estimated: not measured).
const int minimumColumns = 20;
const int minimumRows = 4;

/// The window width for `columns`: 10 + 7 · columns + 27 (80 → 597).
double windowWidth(int columns) =>
    gridPadding.left + cellSize.width * columns + gridPadding.right;

/// The window height for `rows`: 68 + 7 + 14 · rows + 10 (24 → 421).
double windowHeight(int rows, {bool findBar = false}) =>
    chromeHeight +
    gridPadding.top +
    cellSize.height * rows +
    gridPadding.bottom +
    (findBar ? findBarHeight : 0);

/// The default window size: 597 × 421.
Size get defaultWindowSize =>
    Size(windowWidth(defaultColumns), windowHeight(defaultRows));

/// The smallest window size.
Size get minimumWindowSize =>
    Size(windowWidth(minimumColumns), windowHeight(minimumRows));

/// The cursor blinks 500 ms on, 500 ms off when a program asks for a blinking shape; the
/// default is steady.
const Duration cursorBlinkHalf = Duration(milliseconds: 500);

/// The ANSI palette, identical in light and dark (sRGB).
const List<Color> ansiNormal = [
  Color(0xFF000000),
  Color(0xFF990100),
  Color(0xFF00A502),
  Color(0xFF999901),
  Color(0xFF0021B2),
  Color(0xFFB200B2),
  Color(0xFF02A5B3),
  Color(0xFFBFBFBF),
];
const List<Color> ansiBright = [
  Color(0xFF666666),
  Color(0xFFE60000),
  Color(0xFF02D801),
  Color(0xFFE6E600),
  Color(0xFF0033FF),
  Color(0xFFE500E5),
  Color(0xFF03E6E6),
  Color(0xFFE5E5E5),
];

/// A colour profile of the grid (values measured on the reference's default profiles; the
/// names are ours).
@immutable
class GridColors {
  const GridColors({
    required this.background,
    required this.foreground,
    required this.bold,
    required this.selection,
    required this.cursor,
    this.normal = ansiNormal,
    this.bright = ansiBright,
  });

  final Color background;
  final Color foreground;
  final Color bold;
  final Color selection;
  final Color cursor;
  final List<Color> normal;
  final List<Color> bright;

  TerminalTheme theme({
    required Color selection,
    Color searchHit = const Color(0xFFC8C8C8),
  }) => TerminalTheme(
    cursor: cursor,
    selection: selection,
    foreground: foreground,
    background: background,
    black: normal[0],
    red: normal[1],
    green: normal[2],
    yellow: normal[3],
    blue: normal[4],
    magenta: normal[5],
    cyan: normal[6],
    white: normal[7],
    brightBlack: bright[0],
    brightRed: bright[1],
    brightGreen: bright[2],
    brightYellow: bright[3],
    brightBlue: bright[4],
    brightMagenta: bright[5],
    brightCyan: bright[6],
    brightWhite: bright[7],
    searchHitBackground: searchHit,
    searchHitBackgroundCurrent: selection,
    searchHitForeground: foreground,
  );
}

List<Color> _hex(List<int> values) => [for (final v in values) Color(v)];

/// The other measured default profiles, under our own names (colours only).
final Map<String, GridColors> extraProfiles = {
  'night glass': GridColors(
    background: const Color(0xFF262C38),
    foreground: const Color(0xFFE6E6E6),
    bold: const Color(0xFFF0F0F0),
    selection: const Color(0xFF334D5F),
    cursor: const Color(0xFF9D9D9D),
    normal: _hex([
      0xFF35424B, 0xFFB45647, 0xFF6CAA71, 0xFFC4AC62, //
      0xFF6D96B4, 0xFFBD7BCD, 0xFF7CCACD, 0xFFDEE5EB,
    ]),
    bright: _hex([
      0xFF475C6D, 0xFFDF6C5A, 0xFF79BD7E, 0xFFE5C872, //
      0xFF67B6ED, 0xFFD389E5, 0xFF84DEE0, 0xFFE5EFF5,
    ]),
  ),
  'day glass': GridColors(
    background: const Color(0xFFF6F6F6),
    foreground: const Color(0xFF3A4851),
    bold: const Color(0xFF303D44),
    selection: const Color(0xFFE5ECF1),
    cursor: const Color(0xFF919191),
    normal: _hex([
      0xFF2C3840, 0xFFB45647, 0xFF6CAA71, 0xFFC4AC62, //
      0xFF5685A7, 0xFFAD64BE, 0xFF6AC6CA, 0xFFC1C8CC,
    ]),
    bright: _hex([
      0xFF506573, 0xFFDF6C5A, 0xFF79BD7E, 0xFFE5C872, //
      0xFF49A2E2, 0xFFD389E5, 0xFF77E1E5, 0xFFD8E1E7,
    ]),
  ),
  'meadow': const GridColors(
    background: Color(0xFF13773D),
    foreground: Color(0xFFFFF0A5),
    bold: Color(0xFFFFB03C),
    selection: Color(0xFFB64826),
    cursor: Color(0xFF8E2900),
  ),
  'phosphor': const GridColors(
    background: Color(0xFF0D0D0D),
    foreground: Color(0xFF27FE13),
    bold: Color(0xFF00FA00),
    selection: Color(0xFF494BDB),
    cursor: Color(0xFF38FE26),
  ),
  'paper': const GridColors(
    background: Color(0xFFFEF49C),
    foreground: Color(0xFF000000),
    bold: Color(0xFF000000),
    selection: Color(0xFFBFB875),
    cursor: Color(0xFF9D9D9D),
  ),
  'parchment': const GridColors(
    background: Color(0xFFDFDBC3),
    foreground: Color(0xFF4D2E2D),
    bold: Color(0xFF933A21),
    selection: Color(0xFF929077),
    cursor: Color(0xFF665656),
  ),
  'deep sea': const GridColors(
    background: Color(0xFF2B66C8),
    foreground: Color(0xFFFFFFFF),
    bold: Color(0xFFFFFFFF),
    selection: Color(0xFF2886FF),
    cursor: Color(0xFF9D9D9D),
  ),
  'graphite': const GridColors(
    background: Color(0xFF141414),
    foreground: Color(0xFFF4F4F4),
    bold: Color(0xFFFFFFFF),
    selection: Color(0xFF525252),
    cursor: Color(0xFF606060),
  ),
  'desert': const GridColors(
    background: Color(0xFF8D4136),
    foreground: Color(0xFFD6C9A7),
    bold: Color(0xFFE5C72B),
    selection: Color(0xFF3D1917),
    cursor: Color(0xFFFFFFFF),
  ),
  'silver': const GridColors(
    background: Color(0xFF8A8A8A),
    foreground: Color(0xFF000000),
    bold: Color(0xFFFFFFFF),
    selection: Color(0xFF787A9B),
    cursor: Color(0xFFE0E0E0),
  ),
};

/// The default profile and the window chrome around it, for one appearance.
@immutable
class Profile {
  const Profile({
    required this.grid,
    required this.inactiveSelection,
    required this.chrome,
    required this.title,
    required this.titleInactive,
    required this.tabTrack,
    required this.tabActive,
    required this.tabText,
    required this.tabTextInactive,
    required this.separator,
    required this.scrollerKnob,
    required this.scrollerTrack,
    required this.findRing,
  });

  final GridColors grid;

  /// The selection in an inactive window: grey.
  final Color inactiveSelection;
  final Color chrome;
  final Color title;
  final Color titleInactive;
  final Color tabTrack;
  final Color tabActive;
  final Color tabText;
  final Color tabTextInactive;

  /// The line under the tab bar.
  final Color separator;
  final Color scrollerKnob;
  final Color? scrollerTrack;
  final Color findRing;

  /// The grid theme for an active or inactive window.
  TerminalTheme theme({required bool active}) =>
      grid.theme(selection: active ? grid.selection : inactiveSelection);
}

/// Light: background `#ffffff`, text `#000000`, selection `#b3d7ff` (inactive `#e3e3e3`),
/// cursor `#9d9d9d`; title bar `#ffffff`, title `#595959`, tab track `#e8e8e8`, selected tab
/// `#fefdfe`, separator `#e5e5e5`, scroller knob `#7a7a7a`, find ring `#87a4ee`–`#91aef8`.
const Profile lightProfile = Profile(
  grid: GridColors(
    background: Color(0xFFFFFFFF),
    foreground: Color(0xFF000000),
    bold: Color(0xFF000000),
    selection: Color(0xFFB3D7FF),
    cursor: Color(0xFF9D9D9D),
  ),
  inactiveSelection: Color(0xFFE3E3E3),
  chrome: Color(0xFFFFFFFF),
  title: Color(0xFF595959),
  // Estimated: the inactive title was not measured; the toolbar's inactive title grey.
  titleInactive: Color(0xFFBEBEBE),
  tabTrack: Color(0xFFE8E8E8),
  tabActive: Color(0xFFFEFDFE),
  tabText: Color(0xFF4C4B4C),
  tabTextInactive: Color(0xFF828282),
  separator: Color(0xFFE5E5E5),
  scrollerKnob: Color(0xFF7A7A7A),
  scrollerTrack: null,
  findRing: Color(0xFF8CA9F3),
);

/// Dark: background `#1e1e1e`, text `#ffffff`, selection `#3e638b` (inactive `#777777`),
/// cursor `#9d9d9d`; title bar `#2f2f2f`, title `#a1a1a1`, tab track `#464646`, separator
/// `#2e2e2e`, scroller knob `#a2a2a2` on `#272728`. The selected tab and the tab texts in dark
/// were not captured: estimated from the dark tab bar of the file manager (MU-01).
const Profile darkProfile = Profile(
  grid: GridColors(
    background: Color(0xFF1E1E1E),
    foreground: Color(0xFFFFFFFF),
    bold: Color(0xFFFFFFFF),
    selection: Color(0xFF3E638B),
    cursor: Color(0xFF9D9D9D),
  ),
  inactiveSelection: Color(0xFF777777),
  chrome: Color(0xFF2F2F2F),
  title: Color(0xFFA1A1A1),
  titleInactive: Color(0xFF646464),
  tabTrack: Color(0xFF464646),
  tabActive: Color(0xFF5A5A5B),
  tabText: Color(0xFFECECEC),
  tabTextInactive: Color(0xFF8B8B8C),
  separator: Color(0xFF2E2E2E),
  scrollerKnob: Color(0xFFA2A2A2),
  scrollerTrack: Color(0xFF272728),
  findRing: Color(0xFF3A6996),
);

/// The profile for the system appearance.
Profile profileOf(BuildContext context) =>
    MediaQuery.maybePlatformBrightnessOf(context) == Brightness.dark
    ? darkProfile
    : lightProfile;
