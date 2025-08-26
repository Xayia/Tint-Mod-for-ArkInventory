# ArkInventory-ItemLevel by Xayia

A tiny extension for ArkInventory that overlays the item level on item buttons inside ArkInventory.

## Requirements
- World of Warcraft 3.3.5a
- ArkInventory (required)
- LibSharedMedia-3.0 (optional, for font selection)

## What it does
- Shows the item level as a small number at the bottom-right of each item button in ArkInventory.
- Only shows for Armor and Weapon items (no clutter for consumables, keys, etc.).
- Text sits above count/stack text and updates with ArkInventory refreshes.

## Usage
- Type `/aiil` to open the addon options.
- Options allow you to:
  - Choose font size.
  - Choose font (from LibSharedMedia, if installed). If not, the game default font is used.

## Notes & Tips
- If an item just turned up (e.g. via loot), the item level appears as soon as WoW provides item info. Opening the item tooltip or waiting a moment can help.
- If you do not see any overlay, ensure ArkInventory is enabled and loaded for your character.
- The overlay intentionally avoids non-gear to keep your views clean.

## Troubleshooting
- No numbers showing:
  - Make sure ArkInventory is enabled.
  - Try `/reload`.
  - Hover the item once to force WoW to cache its info.
- Font list is empty:
  - Install/enable `LibSharedMedia-3.0` or another addon that registers fonts with it.

## Credits
- Addon by Xayia. Built to integrate seamlessly with ArkInventory while staying lightweight.
