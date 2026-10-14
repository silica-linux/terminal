# Title bar and tabs

Session TE-01. Light captures unless stated. Positions from the window's top-left corner.

The window has no toolbar: a title bar, and under it a tab bar that is **always visible**,
even with a single tab.

| Element | Geometry | Notes |
| --- | --- | --- |
| Window buttons | hit areas 16 × 16 at x 8, 31, 54, y 8 | all gray when the window is inactive |
| Proxy icon | 18 × 18 at (81, 6) | folder icon of the working directory |
| Title | 217 × 16 at (100, 8) for the sample title | bold ≈ 13 pt; `#595959` light, `#a1a1a1` dark |
| Tab bar | 597 × 28 at (0, 32) | full width |
| Tab (single) | 545 × 24 at (10, 34), capsule | label centred |
| Tab close | 18 × 18 at the tab's left end + 4 | only on hover |
| New tab button | 30 × 30 circle at (560, 31) | "+" |
| Split button | 20 × 20 at (579, 66) | above the scroller, opens the split view |

## Title text

`directory — process — columns×rows`, e.g. "test-folder — -zsh — 80×24" (our string:
`windowTitle`). The tab label repeats the path in regular gray and the process in bold dark.

## Colours

| Part | Light | Dark |
| --- | --- | --- |
| Title bar | `#ffffff` | `#2f2f2f` (outer edge `#353535`) |
| Tab track | `#e8e8e8` | ≈ `#464646` |
| Selected tab | `#fefdfe` with a light rim | *unmeasured* |
| Unselected tab | gray fill on the track, gray label | light gray label |

## Two or more tabs

- The tabs share the bar's width (287 + 257 pt in the sample: the newer tab was narrower
  because it carried a 16 × 16 busy indicator at its right end while its shell started).
- On hover, an unselected tab shows × at its left and "…" at its right.
- A new tab starts in the same working directory as the current one.
- Every tab is a native window tab (each counts as its own window for scripting).

## Animations

| Action | First change | Shape | Settled |
| --- | --- | --- | --- |
| New tab (⌘T) | +35 ms after the key | the new tab slides in from the right edge and grows while the old one shrinks; the content switches to the new shell at +75 ms | ≈ **550 ms** |
| Close tab (⌘W) | +53 ms | the closed tab shrinks to nothing, the remaining one widens to the full bar | ≈ **500 ms** |

Easing curve: *unmeasured* (only start and end were read).
