# ArkInventory-Tint by Xayia

Adds custom red tint overlays to items in ArkInventory, based on the types you select.

## Requirements
- World of Warcraft 3.3.5a
- ArkInventory (required)

## What it does
- Overlays a clear red tint (60% opacity) on items whose Armor/Weapon subtype you select in the options.
- The tint remains in place across ArkInventory updates and skin changes.
- Optionally, you can allow Mail items under level 40 (attunable for plate) to remain visible (no red tint).

## Usage
- Type `/aitint` to open the addon options.
- Two sections:
  - **Armor**: Check the subtypes (e.g., Cloth, Leather, Mail, Plate, Shields, etc.) you want tinted.
  - **Weapon**: Check the subtypes (e.g., Daggers, Fist Weapons, Bows, etc.) you want tinted.
- Buttons “All” / “None” quickly select or clear all entries in a section.
- Special option:
  - Under Armor → Mail: "Show Mail under level 40 (attunable for plate)"
    - When enabled, Mail items with Required Level < 40 are not tinted; otherwise Mail follows your selected tinting.

## Tips
- You are in full control: nothing is auto-detected anymore; only selected subtypes are tinted.
- Changes take effect immediately; if something looks stuck, try `/reload`.

## Troubleshooting
- Tint not visible after ticking a subtype:
  - Ensure ArkInventory is enabled and the affected items are visible in ArkInventory windows.
  - Try toggling the subtype off/on again or `/reload`.
- Overlaps with other visual addons/skins:
  - The tint uses its own overlay texture on top of the item icon to avoid interference.
- Debugging:
  - Use `/aitint debug` to print details (type/sub/equip/tint) for hovered/refreshed items.

## Credits
- Addon by Xayia. Designed to be simple, reliable and configurable for different gearing rules.
