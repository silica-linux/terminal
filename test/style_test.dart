import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal/src/style.dart';

void main() {
  test('window sizes from cells (terminal.md › Default size)', () {
    expect(cellSize, const Size(7, 14));
    expect(windowWidth(80), 597);
    expect(windowHeight(24), 421);
    expect(defaultWindowSize, const Size(597, 421));
    expect(windowHeight(35), 575);
    expect(windowWidth(109), 800);
    // The find bar adds 32 pt, the grid keeps its rows.
    expect(windowHeight(24, findBar: true), 453);
    expect(
      minimumWindowSize,
      Size(windowWidth(minimumColumns), windowHeight(minimumRows)),
    );
  });

  test('the bundled font advances exactly one cell', () {
    final painter = TextPainter(
      text: TextSpan(text: 'M' * 80, style: terminalStyle.toTextStyle()),
      textDirection: TextDirection.ltr,
    )..layout();
    expect(painter.width, moreOrLessEquals(80 * 7, epsilon: 0.5));
    expect(painter.height, moreOrLessEquals(14, epsilon: 0.05));
  });

  test('the ANSI palette as measured', () {
    expect(ansiNormal, hasLength(8));
    expect(ansiBright, hasLength(8));
    expect(ansiNormal[1], const Color(0xFF990100));
    expect(ansiNormal[7], const Color(0xFFBFBFBF));
    expect(ansiBright[0], const Color(0xFF666666));
    expect(ansiBright[4], const Color(0xFF0033FF));
    final theme = lightProfile.theme(active: true);
    expect(theme.red, ansiNormal[1]);
    expect(theme.brightWhite, ansiBright[7]);
  });

  test('the default profiles: background, selection, cursor', () {
    expect(lightProfile.grid.background, const Color(0xFFFFFFFF));
    expect(darkProfile.grid.background, const Color(0xFF1E1E1E));
    expect(lightProfile.grid.selection, const Color(0xFFB3D7FF));
    expect(darkProfile.grid.selection, const Color(0xFF3E638B));
    expect(lightProfile.grid.cursor, const Color(0xFF9D9D9D));
    expect(darkProfile.grid.cursor, const Color(0xFF9D9D9D));
    // Grey selection when the window is inactive.
    for (final profile in [lightProfile, darkProfile]) {
      expect(profile.theme(active: true).selection, profile.grid.selection);
      final inactive = profile.theme(active: false).selection;
      expect(inactive, profile.inactiveSelection);
      expect(inactive.r, inactive.g);
      expect(inactive.g, inactive.b);
    }
    expect(extraProfiles, hasLength(10));
  });

  test('cursor blink 500/500 ms, tab animation ~550 ms', () {
    expect(cursorBlinkHalf, const Duration(milliseconds: 500));
    expect(tabEnter, const Duration(milliseconds: 550));
    expect(tabBarHeight, 28);
    expect(tabHeight, 24);
    expect(newTabSide, 30);
    expect(findBarHeight, 32);
    expect(chromeHeight, 68);
  });
}
