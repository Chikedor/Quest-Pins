# Technical research notes

Research date: 2026-08-11–2026-08-16.

## Supported versions

- Fields of Mistria 1.0.3, Steam build 24742087.
- MOMI/MMAPI 0.15.5, tag `v0.15.5`, commit `9b90ee213309e7aaca5870ac43272682b6f595ad`.

## Player-visible objective

Allow active quests to be pinned from the Journal, retain them per save, show their current objective and relevant inventory counts in a compact HUD panel, and emit a vanilla-style sound and toast when a newly obtained item advances a pinned quest.

Non-goals for 0.1.x: parsing localized objective prose, altering quest progression, tracking completed quests, or claiming acquisition alerts for non-item requirements.

## Verified contracts

- `QUEST_LOG.active.get(key)` returns an `ActiveQuest` with `quest`, `quest_name`, `blackboard`, and `current_stage` (`assets/gml/scripts/GameplaySystems/Quests/QuestLog.gml`, game 1.0.2).
- A `QuestTask` exposes `description`, `requirements`, and `query_targets`; `Requirement.HasItem` parses to an array of `[ItemId, amount]` pairs (`QuestDatabase.gml` and `Requirements.gml`, game 1.0.2).
- Vanilla renders those requirements from `ARI.inventory` through `Listing.Item`, `gather_listings_from_requirements`, and `render_quest_requirement` (`QuestLogMenu.gml`, game 1.0.2).
- `ARI.inventory.item_id_quantity(item_id)` returns the live quantity across inventory slots (`Inventory.gml`, game 1.0.2).
- `ToolbarMenu.update()` runs after its `InventorySubscriber` detects a change, then MOMI 0.15.1 emits `ui.menu_refreshed`; this supplies a bounded inventory-change edge without polling every acquisition source.
- `ToolbarMenu.canvas` is a full HUD menu canvas under `ANCHOR.screen_canvas`; HUD hide/show transitions apply to that menu canvas, so tracker children follow vanilla HUD visibility.
- The vanilla quest-detail scroller and pilot can host an idempotent added button. Quest Log rebuilds its right scroller without a general refresh hook, so the mod uses a watcher anchored outside `right_body`, matching the verified Find My Mistrian lifecycle pattern.
- `TANGO.name_exists()` and `TANGO.play()` are the supported direct sound path; `SoundEffects/UI/UIExtraPositiveClick` is used by vanilla quest acceptance.

The contracts above were rechecked for Fields of Mistria 1.0.3. `Inventory.gml`, `QuestLog.gml`, `Requirements.gml`, and `InfoHudMenu.gml` are byte-identical to the previously verified pristine sources. Differences in `QuestLogMenu.gml`, `SettingsMenu.gml`, `ToolbarMenu.gml`, and `Node.gml` are limited to the expected MMAPI localization rewrite and UI hook seams. Evidence was read from the pristine 1.0.3 backup, the installed asset, and the official MOMI 0.15.5 source/tag.

## Design decisions

- Pinned keys live in MMAPI's per-save JSON sidecar, keeping vanilla save data untouched.
- The tracker is a child of the vanilla Toolbar canvas and uses vanilla nine-slice boxes, fonts, LUTs, quest icons, and requirement renderers.
- Its top coordinate is derived from `InfoHudMenu.bottom_backplate` (`y + height + 4`) rather than a guessed screen coordinate. This keeps it below both gold and essence, including the vanilla 24-to-15-pixel height change when essence is unavailable.
- `tracker_width` is configurable from 88 to 240 pixels. Version 0.1.6 exposes five presets (88, 112, 160, 208, and 240 pixels); objective and requirement wrapping adapt while fonts and icons remain at native pixel scale.
- The vanilla-style Settings category reuses `SettingsMenu.create_category`, `button`, `checkbox`, `element`, and `create_options_popup`, so mouse, keyboard, and controller behavior stays native while values persist through MMAPI config.
- Direct `local_get()` and `mmapi_local_get()` calls from the added mod GML file returned the native `MISSING` sentinel for dynamically assembled mod keys, although the same exact keys were present in the final translation TOML. A short-lived `Node.set_key()` helper resolves popup values after the menu exists, but resolving a temporary node during the category's initial construction is still too early. Persistent setting-button labels therefore receive their dynamic keys directly through `set_key()`; popup formatters use the short-lived node only after construction.
- The tracker can align left or right. Its position is recomputed every tick from live vanilla layout state: `InfoHudMenu.bottom_backplate` on the right, or `VitalsMenu.root` plus its animated `occupied_space` array on the left. It therefore follows essence availability and the visibility of health, stamina, mana, and status effects without user offsets.
- The tracker uses the same right inset as `InfoHudMenu.bottom_backplate` (`-6`). Header text disables line wrapping and is width-truncated with an ellipsis so it cannot escape the 21-pixel header.
- Acquisition detection compares item ids required by the current stages of every active quest by default, and only on Toolbar inventory refreshes. An in-game setting can limit this scope to pinned quests.
- Alert scope has its own signature, separate from the tracker signature. Loading a save, accepting or completing a quest, advancing a stage, changing alert scope, or changing the pinned set while using pinned-only scope rebuilds the inventory baseline without generating retroactive alerts.
- When one acquisition helps multiple monitored quests, each affected quest may receive its own toast, while the sound plays once for that refresh.

## Rejected approaches

- `array_pos(array, value) >= 0` is not a safe membership test in this runtime. When the value is absent, `array_pos` throws `value was not found in array` instead of returning `-1`. The first in-game Quest Log test captured this at `QuestPins.gml:172`. Membership checks use `array_contains`; `array_pos` is now called only after presence is established or when the element is structurally guaranteed to be a child of the target scroller.
- Passing a local anonymous callback into a helper and reading outer local variables from that callback is unsafe in this runtime. Quest Pins 0.1.1 captured `_relevant` this way; at execution the VM looked for it as an object field and threw `no such field "_relevant"`. Version 0.1.2 replaces the callback traversal with an explicit array of requirement structs and ordinary loops.

## Automated validation

The official MOMI 0.15.5 CLI was run against the installable directory and the pristine game 1.0.3 backup:

```powershell
ModsOfMistriaInstaller-cli.exe --lint .\quest_pins C:\path\to\assets.bak.zip --strict-lints --compile-check require
```

Latest result for version 0.1.6:

```text
lint chikedor.quest_pins v0.1.6
  gml: 1 file(s) installing under scripts/chikedor_quest_pins/
  RESULT: OK - the apply would install this mod
```

A real MOMI 0.15.5 apply with Find My Mistrian and Quest Pins enabled passed the compile gate (`100` seamed/framework files plus one GML file for each mod) and reported `2 mod(s) installed`, including Quest Pins 0.1.5.

## Manual validation

Validated in game on 2026-08-12 against Fields of Mistria 1.0.2 and MOMI/MMAPI 0.15.1:

- Opening the Quest Log and switching between active quests remains stable.
- Pinning missions from the quest-detail button remains stable after the two rejected runtime approaches were replaced.
- Three pinned quests render below the vanilla gold and essence block without covering it.
- Long tracker titles stay inside their headers.
- The in-game Quest Pins settings category and tracker-size presets work.

The repository screenshots under `docs/images/` capture the verified pin control and three-card HUD layout.

Validated in game on 2026-08-17 for Quest Pins 0.1.6:

- The expanded Settings category renders in Spanish without `MISSING` values after persistent option labels were changed to receive localization keys through `Node.set_key()`.
- The size, panel-side, and item-alert-scope selectors open correctly, and the side choices are presented in the natural visual order: left on the left, right on the right.
