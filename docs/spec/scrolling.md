# Scrolling and latency

Session TE-01.

## Scroller

| Item | Light | Dark |
| --- | --- | --- |
| Column | 19 wide, at the right edge, outside the text area | same |
| Knob | **11** wide, rounded, `#7a7a7a` on the white background | `#a2a2a2` on a `#272728` track |

- The scroller was visible at all times in the session. Whether it hides itself depends on
  a system-wide scroll bar preference that was left at its value; the auto-hiding variant
  is *unmeasured*.

## Scrollback

- Output that arrives in one burst (2000 numbered lines) is shown already scrolled to the
  bottom in **one frame**, 30 ms after Return. No scrolling animation.
- Mouse wheel: each wheel event moves the content in the same frame, with no smoothing and
  no inertia (30 line events about 35 ms apart).
- Scrollback length: limited only by available memory (default profile setting).

## Typing

- Each typed character is echoed in the first frame after its key (+13 ms).
