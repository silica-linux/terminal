# Colours

Session TE-01. All values sRGB.

## Default scheme

The default profile is **dynamic**: white background in the light appearance, dark in the
dark one. Text in the default colour flips between black and white with it.

| Role | Light | Dark |
| --- | --- | --- |
| Background | `#ffffff` | `#1e1e1e` |
| Text, bold text | `#000000` | `#ffffff` |
| Cursor (block) | `#9d9d9d` | `#9d9d9d` |
| Selection, active window | **`#b3d7ff`** | **`#3e638b`** |
| Selection, inactive window | `#e3e3e3` | `#777777` |
| Find match while the find field has focus | `#c8c8c8` | *unmeasured* |

## ANSI palette

The same 16 colours in light and dark.

| | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Normal | `#000000` | `#990100` | `#00a502` | `#999901` | `#0021b2` | `#b200b2` | `#02a5b3` | `#bfbfbf` |
| Bright | `#666666` | `#e60000` | `#02d801` | `#e6e600` | `#0033ff` | `#e500e5` | `#03e6e6` | `#e5e5e5` |

- The 256-colour cube, the grayscale ramp and 24-bit colour (SGR 38;2 / 48;2) are all
  rendered.
- Bright colours are **not** used for bold text in the default profile.

Other preset schemes: [settings.md](settings.md).
