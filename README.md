# Rhodan's Markers

Rhodan's Markers helps you identify the tank and healer in a five-player World of Warcraft dungeon. A button beside the target frame lets you choose a role, then click again to place its configured raid marker.

[Download on CurseForge](https://www.curseforge.com/wow/addons/rhodans-markers) · [Player guide](https://github.com/rhodan412/RhodansMarkers/wiki) · [Report a bug or suggest a feature](https://github.com/rhodan412/RhodansMarkers/issues/new/choose)

## How to use it

In a five-player dungeon, the button appears to the right of the target frame when Rhodan's Markers is enabled and an eligible tank or healer is available.

1. With no eligible tank or healer targeted, **left-click** the button to target the assigned tank, or **right-click** it to target the assigned healer. The button can remain visible when you have no target.
2. Once you target a tank or healer in your party, the button displays the role and configured raid icon. Click it to apply that marker. The default markers are **Star** for the tank and **Moon** for the healer.

The addon uses assigned group roles first. If you target a party member whose role is unassigned, it can use their specialization when inspect data is available; it also checks your own specialization when your assigned role lags behind a spec change. Target selection from the button uses assigned roles, with a specialization fallback for your own character.

The button works only outside combat. It does not mark the group automatically, and it does not appear outside a two-to-five-member dungeon party. Marking also depends on your character's permission to set raid targets.

## Settings and commands

Open the addon settings with `/rm`. You can enable or disable the addon, turn tank and healer marking on or off separately, and choose each role's raid icon. The two icons must differ.

The **Marking keybind** option assigns a key to the button's left-click action. Left-click the key picker and press a key combination to set it; right-click the picker to clear it. With no eligible role targeted, the key targets the tank. With an eligible role targeted, it applies that role's marker. The keybind is optional.

| Command | Action |
| --- | --- |
| `/rm` | Open Rhodan's Markers settings |
| `/rm on` | Enable the addon |
| `/rm off` | Disable the addon |

## Client support

The GitHub source targets Retail 12.1.0, TBC Anniversary 2.5.6, Classic Season of Discovery 1.15.9, and Classic Forever 1.60.1. Check the [CurseForge files page](https://www.curseforge.com/wow/addons/rhodans-markers/files) for available downloads.

For setup details, button behavior, and troubleshooting, see the [wiki](https://github.com/rhodan412/RhodansMarkers/wiki). Please use [GitHub Issues](https://github.com/rhodan412/RhodansMarkers/issues/new/choose) for bug reports and feature requests; include the addon version and WoW client so the report can be matched to the right build.
