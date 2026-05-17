# Vendor UI Assets

This folder contains third-party UI assets that are safe to reuse in the game prototype.

Selection rule: only include assets with clear permissive licenses and reusable UI components. These are not visual references copied from commercial games.

## Installed Packs

| Folder | Pack | Source | License | Practical Use |
| --- | --- | --- | --- | --- |
| `kenney_pixel_ui_pack/` | Kenney Pixel UI Pack | https://kenney.nl/assets/pixel-ui-pack | CC0 | Pixel panels, buttons, 9-slice UI, useful for HUD chips, dialogue panels, choice buttons. |
| `kenney_ui_pack/` | Kenney UI Pack 2.0 | https://kenney.nl/assets/ui-pack | CC0 | General-purpose buttons, sliders, checkmarks, arrows, icons, fonts, and UI sounds. |
| `kenney_ui_pack_pixel_adventure/` | Kenney UI Pack - Pixel Adventure | https://kenney.nl/assets/ui-pack-pixel-adventure | CC0 | Pixel UI tiles and panels, useful for small icons, inventory slots, and blocky UI framing. |

## Local Verification

- Zip archives are kept in `_downloads/` for traceability.
- All three zip archives passed `unzip -t`.
- License files are included in each extracted folder.
- The installed vendor folder currently contains 1875 files and is about 9.4 MB.

## Recommended First Use

For the current project, start with:

- `kenney_pixel_ui_pack/9-Slice/` for dialogue panels, status bars, and top HUD chips.
- `kenney_ui_pack/PNG/*/Default/button_round_*.png` for action button base states.
- `kenney_ui_pack/PNG/*/Default/button_rectangle_*.png` for choice button states.
- `kenney_ui_pack/PNG/*/Default/slide_*.png` for settings and progression sliders.
- `kenney_ui_pack/Font/` only for temporary Latin UI; do not rely on it for final Chinese text rendering.

## Project-Specific Notes

These packs solve base UI construction, not the final identity of the game. The Xinghuan AI panels, system-reversal overlays, Chinese school/corporate UI language, and post-AI cyberpunk details still need project-specific assets or styling.

Do not bake Chinese text into these images. Use Godot `Label` nodes over 9-slice panels so text remains readable, editable, and localizable.
