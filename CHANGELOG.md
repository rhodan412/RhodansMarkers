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