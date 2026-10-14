# Terminal: parity

Parity with the reference is written here only from measurements: TE-01, `plan/reference/terminal.md`
(silica-reference 23654e2), macOS 27.0.1 at 1×, profile Basic. The values live in `lib/src/style.dart`;
`test/style_test.dart` and `test/window_test.dart` hold them.

## Measured and applied

| Item | Reference | Terminal |
| --- | --- | --- |
| Cell | 7 × 14 pt | 7 × 14 pt: JetBrains Mono NL at 7 / 0.6 = 11.67 pt (advance 0.6 em), line height 1.2; residual < 0.01 pt. Our font stays ours |
| Text insets | left 10, top 7, bottom 10, right 27 (8 + scroller 19) | same (`gridPadding`) |
| Width | 10 + 7 · cols + 27 (80 → 597, 109 → 800) | `windowWidth`, same |
| Height | 68 + 7 + 14 · rows + 10 (24 → 421, 35 → 575) | `windowHeight`, same |
| Default size | 80 × 24 = 597 × 421 pt | `SilicaWindow.setSize(597 × 421)` at launch (silica_ui 0.21.0) |
| Minimum size | not measured | 20 × 4 cells = 177 × 141 pt (`setSizeLimits`), **ours** |
| Live title | directory, process and cols×rows, updates during the drag | "title — cols×rows", rebuilt the frame after each resize |
| Title | AX (+100, +8), bold ≈ 13, `#595959` / `#a1a1a1` | same; inactive colour `#bebebe` / dark default **estimated** |
| Tab bar | always visible, 28 pt at y +32 | always visible, 28 pt |
| Tab | capsule 24 pt at (+10, +34), track `#e8e8e8`, selected pill `#fefdfe`; label path gray, process bold | same; dark track `#464646`, dark pill `#5a5a5b` and dark labels **estimated** |
| "+" button | 30 × 30 circle at (+560, +31) | 30 pt circle 7 pt from the right, y +31 |
| New tab | slides in from the right, settled ~550 ms | slides in from the right, 550 ms ease-out, inserted after the current tab |
| Close tab | shrinks away, ~500 ms | shrinks away, 500 ms |
| Separator under the tab bar | y +68, `#e5e5e5` / `#2e2e2e` | same |
| Background | `#ffffff` / `#1e1e1e` | same |
| Text / bold | `#000000` / `#ffffff` | same |
| Selection, active | `#b3d7ff` / `#3e638b` | same |
| Selection, inactive window | `#e3e3e3` / `#777777` | same |
| Find highlight | `#c8c8c8` | same (light and dark; dark not measured) |
| ANSI palette | normal and bright as in the table, same in light and dark | same (`ansiNormal`, `ansiBright`) |
| Other default profiles | ten more profiles | `extraProfiles`, colours only, our own names (night glass, day glass, meadow, phosphor, paper, parchment, deep sea, graphite, desert, silver); not selectable yet |
| Cursor | block 7 × 14 `#9d9d9d`, glyph visible | block `#9d9d9d` |
| Cursor, inactive | hollow 1 pt outline (window inactive or focus in the find field) | the grid loses focus when the window is inactive or the find field has it: xterm draws the outline |
| Cursor blink | off by default; 500 / 500 ms hard toggle when requested | off; `cursorBlinkHalf` 500 ms recorded |
| Scroller | column 19 pt, knob 11 pt; `#7a7a7a` on white, `#a2a2a2` on `#272728` | same, always visible |
| Find bar | 32 pt under the tab bar, window grows 421 → 453; field 482 × 22 at (+7, +73), ring `#87a4ee`–`#91aef8`; pair 45 × 22; done button 44 × 22 | same; the window grows and shrinks by 32 pt (`setSize`); ring `#8ca9f3`, dark ring `#3a6996` **estimated** |
| Scrolling | output and wheel in the same frame, no smoothing | xterm, same frame |

## Gaps

- **Resize does not snap to whole cells.** The reference uses resize increments; Ossido / silica_ui have no size
  increments, and correcting the size with `setSize` while the user drags would fight the compositor. The window
  takes any size, the grid uses the whole cells that fit and the rest stays as inset. Needs size increments in
  silica-desktop.
- **Blinking cursor shapes:** xterm.dart records DECSCUSR blink but does not animate it; the 500 / 500 ms value is
  ready for when it does (or for our own painter).
- **Bottom-anchored grow** (scrollback reappears above when the window grows taller): not verified with xterm.dart.
- **Strikethrough (SGR 9):** the reference does not draw it; xterm.dart does. Dim (SGR 2) not compared.
- **Block elements:** the reference draws "█" as the font glyph (7 × 10), not a full cell; not compared.
- **Not built:** proxy icon (18 × 18 at +81, +6), tab close × and "…" on hover, the busy indicator of a starting
  tab, split pane (⌘D, button at +579, +66), Inspector (⌘I), Settings and profile choice, global menus
 , ⌘1–⌘9, marks and bookmarks, ⌘K.
- **Dark captures** of tabs, find bar and Inspector are missing in the reference: their dark colours are estimates.
- **Live check:** not run; the values are held by the tests only.
