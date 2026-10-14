# Split view and find bar

Session TE-01, light only.

## Split view (⌘D)

- Splits the window horizontally into two views of **the same session** (one scrollback,
  one shell), not a second shell.
- The window **grows** from 421 to 445 so that each half keeps 12 rows; the title shows
  "80×12".
- Splitter 7 pt, gray, with a small dot in the middle.
- Each half has its own scroller, plus a split button and a close-split button above it.
- ⇧⌘D closes the split; the window returns to 80 × 24 and 421 pt.

## Find bar (⌘F)

| Item | Value |
| --- | --- |
| Bar | **32** tall, inserted under the tab bar; the window grows 421 → 453, the text area keeps its size |
| Search field | 482 × 22 at (7, 73), blue focus ring (≈ `#87a4ee`–`#91aef8`) |
| Previous / next | segmented pair 45 × 22 (`findPrevious`, `findNext`) |
| Done | button 44 × 22 (`findDone`) |

- Return finds the next match and selects it; while the focus stays in the field the match
  is highlighted in gray `#c8c8c8`.
- Done removes the bar and the window shrinks back by 32.
- Dark appearance: *unmeasured*.
