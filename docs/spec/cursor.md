# Cursor

Session TE-01. Shapes were requested with DECSCUSR escape sequences; the profile default
is the block.

| Shape | Sequence | Geometry |
| --- | --- | --- |
| Block (default) | `CSI 2 SP q` | the full 7 × 14 cell, `#9d9d9d`; the character under it stays readable |
| Underline | `CSI 4 SP q` | 7 × 1 on the bottom row of the cell |
| Bar | `CSI 6 SP q` | 1 × 14 on the left edge of the cell |

- When the window is inactive, or the focus is in the find field, the block becomes a
  **hollow 1 pt outline**.
- By default the cursor does not blink.
- A blinking shape (`CSI 1 SP q`) blinks **500 ms on, 500 ms off**, switching hard with no
  fade. Successive toggles were read at a steady ≈ 500 ms spacing over several seconds.
- Blinking enabled from the profile instead of an escape: *unmeasured*.
