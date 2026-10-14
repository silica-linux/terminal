# Window and grid

Session TE-01. Default profile. Geometry:
[diagrams/window-geometry.svg](diagrams/window-geometry.svg).

| Item | Value |
| --- | --- |
| Default size | **80 × 24** cells; window **597 × 421** |
| Font | the reference system's monospaced face, Regular, **11 pt** (Silica: JetBrains Mono NL, see `ASSETS.md`) |
| Cell | **7 × 14** (80 columns = 560 pt; row pitch 14) |
| Text inset | left **10**, top **7** (from the top of the content area), bottom **10** |
| Right side | 27 = 8 pt gap + a 19 pt scroller column that never overlaps the text |
| Width | 10 + 7 × columns + 27 (80 → 597; 109 → 800 checked) |
| Height | 68 (title bar and tab bar) + 7 + 14 × rows + 10 (24 → 421; 35 → 575 checked) |
| Content area | starts at y **68**; a 1 pt line under the tab bar, `#e5e5e5` light / `#2e2e2e` dark |
| Corner radius | ≈ 14–16 (*provisional*: read from the edge shape) |

The cell was measured with reverse-video cells, so it is the true advance and line pitch,
not the glyph ink.

## Resizing

- The window resizes in whole cells only (resize increments of 7 × 14).
- During a drag the title shows the new size in cells live ("97×30"); there is **no** size
  overlay over the content.
- When the window gets taller, the text stays anchored to the bottom: lines that had
  scrolled off come back at the top.

## Glyph rendering in the grid

- The full block "█" is drawn as the font's glyph (7 × 10), not stretched to the 7 × 14
  cell: block elements are not special-cased in the default profile.
- Capital "M" is ≈ 8 tall.
- Bold uses the bold face, without brightening the colour.
- Italic uses a real italic face.
- Dim (SGR 2) is drawn in a lighter gray.
- Strikethrough (SGR 9) is **not** drawn.
