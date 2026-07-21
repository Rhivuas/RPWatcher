# RPWatcher

## Very short summary

Shows friendly players who currently target you—or targeted you earlier—through visible nameplates, with optional Total RP 3 names and profile access.

## Description

RPWatcher is a German-language World of Warcraft Retail addon designed for roleplayers. It only considers friendly player characters whose nameplates are currently visible and available through the WoW API. A player is added to the compact watcher list only after the addon has confirmed that they targeted your character at least once.

RPWatcher distinguishes three states: currently targeting you, targeted you earlier, and unknown because the nameplate is no longer visible. Elapsed-time labels show how long the current targeting period has lasted or how much time has passed since the last detected change.

The interface is dark, compact, and inspired by modern WoW and Total RP 3 panels. Window position, size, scale, opacity, and locking can be configured. Optional Total RP 3 integration adds known roleplay names and local profile opening.

## Features

- friendly players with visible nameplates as the only detection source
- players appear only after a confirmed targeting event
- GUID-based recognition without duplicate entries
- Current, Previous, and Unknown states
- configurable retention time for unknown watchers
- movable, resizable, scalable, and lockable window
- optional auto-hide when the list is empty
- virtualized list for larger watcher counts
- optional Total RP 3 roleplay names and profile opening
- throttled profile requests
- non-persistent nameplate, performance, and synthetic stress diagnostics

## Technical limitations

RPWatcher detects target selection, not gaze direction. It can only inspect visible nameplate units exposed by the WoW API. Extremely short target changes may happen between two scans. Once a nameplate is unavailable, the player’s actual target state is unknown.

## Total RP 3

Total RP 3 is optional and is not bundled with RPWatcher. Without it, RPWatcher uses the character’s full normal WoW name and remains fully functional.

## Privacy

No telemetry, advertising, or external services. Watchers, other players’ GUIDs, roleplay names, profiles, and diagnostics are never stored permanently. `RPWatcherDB` contains only the user’s own window and display settings.

## Installation

Copy the `RPWatcher` folder from `RPWatcher-0.9.0.zip` into `World of Warcraft\_retail_\Interface\AddOns\`, then restart the game. Friendly nameplates must be enabled for real-player detection.

## Support

Bug reports should include addon/game versions, reproduction steps, expected and actual behavior, BugSack output, and—when relevant—`/rpw plates` or `/rpw perf report`. Do not submit account data, GUIDs, or complete roleplay profiles.

## License

MIT License. Copyright 2026 Mercia.
