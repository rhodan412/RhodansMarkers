12.1.0.0

	Highlights
		- The button beside the target frame now lets you left-click to target the group's tank or right-click to target its healer, then click again to apply the configured marker.

	Core.lua
		- Replaced automatic party marking with a center button for a targeted tank or healer. Assigned role takes priority over specialization, with inspect data requested when needed; clicks can replace existing marks and do nothing during combat.
		- Added Alt+Shift+A click binding, protected click action for Retail 12 and Forever, and classic settings-panel fallback.
		- Switched the Retail/Forever marking control to a secure raid-target action with explicit up-click handling, a compact Tank/Healer label beside TargetFrame, combat disabling, and temporary Retail click diagnostics so selected markers can be verified. (2026.09.17.2059)
		- Removed the temporary Retail click diagnostics after successful testing, showed the configured raid icon next to Tank/Healer, and registered both click phases so Alt+Shift+A reaches the secure button on key release. (2026.09.17.2105)
		- Added a keybind picker to the options panel; it stores the selected chord in the account-wide RhodansMarkersSettings SavedVariables table and can be cleared without disabling mouse clicks. (2026.09.17.2116)
		- Removed the automatic Alt+Shift+A binding and applied override bindings only when a key is configured; updated the settings hint to explain how to set or clear a binding. (2026.09.17.2116)
		- Let self-target marking fall back to the player's current tank or healer specialization when the assigned role still reports DAMAGER, and refresh after specialization changes; require a 2-5 member dungeon group so the button does not appear after leaving the party. (2026.09.17.2121)
		- Refresh target eligibility when assigned or LFG roles change, then recheck after follower-party roster reorganization so a player who entered as damage and switched to tank gets the configured self-target button. (2026.09.17.2130)
		- Keep the button available in a five-player dungeon when no eligible tank or healer is targeted, resolve assigned party roles (including the player's specialization fallback), and use left/right clicks to target the tank/healer before returning to the existing marking action. (2026.09.18.0851)
		- Configure separate secure mouse actions for targeting and marking on Retail/Forever, clear both actions in combat, limit legacy clicks to release, and update the options hint for the two-click flow. (2026.09.18.0851)

	RhodansMarkers.toc / RhodansMarkers_Vanilla.toc / RhodansMarkers_TBC.toc / RhodansMarkers-Forever.TOC
		- Declared Retail, Season of Discovery, TBC Anniversary, and Forever interfaces while loading the shared code.


11.2.0.0 (2025-09-20)

	RhodansMarkers.toc
		- Updated version/interface# (2025.09.20)


11.1.5.1

	Core.lua
		- Added functionality to not override current selected tank/healer marks if markers exist unless player is party leader and the current marks don't correspond with current settings. This should remove a lot of the 'spamming' of player markers, especially if multiple players in the dungeon group are using addon (2025.04.28)

	RhodansMarkers.toc
		- Updated version/interface# (2025.04.28)


11.1.0.1 (2025-03-01)

	Core.lua
		- Fixed spacing
		
	RhodansMarkers.toc
		- Updated version# (2025.03.01)
		- Updated interface# (2025.03.01)
		- Added category information for addon (2025.03.01)


11.0.7.1
- Version update

11.0.2.2
- New addon options allowing users to customize role markers

11.0.2.1
- Update TOC and verification of no breaking changes

1.1.2
- Update TOC

1.1.0
- Update TOC

1.0.9
- Removed duplicate function

1.0.8
- Bump version

1.0.7
- Removed debug msgs for events

1.0.6
- Modified event handling so markers wouldn't continuously clear and be reapplied needlessly

1.0.5
- Clears Marks after leaving dungeon group & fixed bug that resulted in marks not being restored after clicking the Tomes in Azure Vaults

1.0.0
- Initial Release
