# Technical research notes

Research date: 2026-08-11–2026-08-16.

## Supported versions

- Fields of Mistria 1.0.4, Steam build 24820767.
- MOMI/MMAPI 0.15.6, tag `v0.15.6`, commit `288d843a57df4ee7c7bab224925fde1ce54d1bf4`.

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

### Fields of Mistria 1.0.4 build 24820767

Audited on 2026-08-19 and validated with the official compatibility release on 2026-08-20. Steam replaced the executable and `assets.zip` while leaving `assets.bak.zip` from the preceding build. The restored current archive (SHA-256 `e55ef6bcaa7430008a6fcae7980ef06ca6912bb10431c177807b366a0fc5a450`) contained no Quest Pins or MMAPI paths and exposed the patch's new per-`MonsterId` quest tracking in `Requirements.gml`, `QuestLog.gml`, and `QuestLogMenu.gml`. Quest Pins delegates those rows to vanilla, and its directly used inventory, HUD, settings, and storage sources remained byte-identical.

Official MOMI 0.15.5 failed its global `dungeon_floor_bracket` seam against the changed `enter_dungeon.gml` before compiling Quest Pins. MOMI 0.15.6 (`v0.15.6`, commit `288d843a57df4ee7c7bab224925fde1ce54d1bf4`, CLI SHA-256 `2d97a7754dc14bad3e7220a85d20e5684aac083c88dacf93f8b393d1f89ce3ac`) re-anchors the framework for game 1.0.4. Its strict lint and required compile check pass Quest Pins 0.1.8 against this exact pristine archive.

## Design decisions

- Pinned keys live in MMAPI's per-save JSON sidecar, keeping vanilla save data untouched.
- The tracker is a child of the vanilla Toolbar canvas and uses vanilla nine-slice boxes, fonts, LUTs, quest icons, and requirement renderers.
- Its top coordinate is derived from `InfoHudMenu.bottom_backplate` (`y + height + 4`) rather than a guessed screen coordinate. This keeps it below both gold and essence, including the vanilla 24-to-15-pixel height change when essence is unavailable.
- `tracker_width` is configurable from 112 to 208 pixels. Version 0.1.7 exposes five evenly spaced widths (112, 136, 160, 184, and 208 pixels). The former 88-pixel layout became taller than 112 pixels because objective wrapping dominated its area, while 240 pixels consumed an excessive portion of the screen at common UI scales.
- The vanilla-style Settings category reuses `SettingsMenu.create_category`, `button`, `checkbox`, `element`, and `create_options_popup`, so mouse, keyboard, and controller behavior stays native while values persist through MMAPI config.
- Direct `local_get()` and `mmapi_local_get()` calls from the added mod GML file returned the native `MISSING` sentinel for dynamically assembled mod keys, although the same exact keys were present in the final translation TOML. A short-lived `Node.set_key()` helper resolves popup values after the menu exists, but resolving a temporary node during the category's initial construction is still too early. Persistent setting-button labels therefore receive their dynamic keys directly through `set_key()`; popup formatters use the short-lived node only after construction.
- The tracker can align left or right. Its position is recomputed every tick from live vanilla layout state: `InfoHudMenu.bottom_backplate` on the right, or `VitalsMenu.root` plus its animated `occupied_space` array on the left. It therefore follows essence availability and the visibility of health, stamina, mana, and status effects without user offsets.
- The tracker uses the same right inset as `InfoHudMenu.bottom_backplate` (`-6`). Header text disables line wrapping and is width-truncated with an ellipsis so it cannot escape the 21-pixel header.
- Tracker requirement rows come from vanilla `gather_listings_from_requirements()` and render through `render_quest_requirement()`. This is required for `Requirement.SuppliedItems` missions such as mine seals: their item progress lives in `SEAL_INVENTORIES`, not `ARI.inventory` or `Requirement.HasItem`.
- After vanilla creates a requirement row, its name node is constrained to one line and truncated with the same measured ellipsis helper as tracker titles. Icons and counters remain untouched, while long localized item names can no longer multiply a card's row height.
- A tested `fnt_cubic_11` compact-body experiment changed the typeface but did not materially reduce its rendered size, so it was removed. All presets retain the standard localized font. Instead, Compact clamps objectives to two measured lines and all other widths clamp them to three; long requirement names remain single-line. The HUD deliberately trades secondary prose for a predictable footprint while the Journal retains the complete text.
- Each tracker header reserves its top-right corner for a 14-pixel vanilla-style mouse button. Its callback receives the quest key explicitly and delegates to the existing safe unpin path.
- Version 0.1.10 makes the remaining card area clickable. It submits the same deferred `obj_ari.ui_journal_request` used by the vanilla HUD, then activates the matching vanilla Quest Log row after the Journal exists; the row's own callback preserves read-envelope and detail-page behavior. Anchor resolves only one hovered node and scans newer nodes first, so the later-created header X retains priority over its tappable parent card.
- Acquisition detection compares item ids required by the current stages of every active quest by default, and only on Toolbar inventory refreshes. An in-game setting can limit this scope to pinned quests.
- Alert scope has its own signature, separate from the tracker signature. Loading a save, accepting or completing a quest, advancing a stage, changing alert scope, or changing the pinned set while using pinned-only scope rebuilds the inventory baseline without generating retroactive alerts.
- When one acquisition helps multiple monitored quests, each affected quest may receive its own toast, while the sound plays once for that refresh.
- `STORAGE_NODES` is the vanilla global registry for furniture nodes carrying inventories. Quest Pins counts a node only when `prototype.interaction_chest` exists, `belongs_to_ari` is true, and `shipping_bin` is false. This includes player-owned chests even when their crafting pull toggle is disabled, while excluding shipping bins, factories, feeders, and non-player storage.
- Chest quantities supplement the HUD display only; vanilla quest fulfillment continues to use `ARI.inventory`, so the inventory progress remains authoritative. Closing a vanilla Storage menu marks the tracker dirty and refreshes chest counts without polling every chest each frame.
- All supplemental HUD stock uses one visual contract: a fixed 14 px row directly below the authoritative requirement, containing vanilla source icons plus `xN` in the standard readable LUT. Every main and secondary sprite is centered inside the same 20 px icon slot beginning at row X=2; counts and item labels begin after that slot instead of after each sprite's variable bounding box. Backpack appears first; when chest stock also exists, its slot anchors eight pixels after the measured end of the backpack count on the same row. The 7-by-6 chest glyph is scaled 2x to match the backpack's visual footprint. Main requirement nodes are pinned to the first line before the row expands, preventing vertical recentering, overlap, and unused label space.
- Chest discovery is independent from pin state. The Journal quest list decorates every active quest whose current `has_item` stage has missing backpack items available in player-owned chests; the selected quest receives a vanilla-style detail section listing the exact stored items and counts.
- Version 0.1.9 makes the Journal source indicator symmetric: a 14-pixel vanilla inventory-header backpack occupies the first slot left of the vanilla read envelope whenever any current `has_item` requirement has backpack stock. The existing 7-pixel storage icon uses that slot when alone and shifts left only when both sources are relevant. These are availability indicators, not completion badges.
- Version 0.1.10 scales the 7-by-6 storage glyph to the same approximate 14-pixel visual footprint as the vanilla envelope and backpack. Journal rows allocate stable 17-pixel slots for pin, backpack, and chest status, and derive their title width from the number of visible indicators. Pin toggles redecorate an open quest list immediately.
- Source icons are created idempotently per live quest row and their alpha/position is refreshed on bounded Toolbar inventory events. This avoids a `STORAGE_NODES` scan every frame while still updating an open Journal after backpack changes.
- A `SuppliedItems` listing retains its target inventory (turn-in box or seal) as the authoritative main counter. Backpack and player-chest quantities are secondary icon-plus-count rows and never alter that counter.

## Rejected approaches

- `add_hover_outline()` is not available on an `ANCHOR.positional` node. Quest Pins 0.1.10 first attempted to add it to the tappable tracker-card root and the runtime rejected mod initialization with `no such field "add_hover_outline"`, preventing every pinned card from rendering. The card keeps its tap callback without a parent outline; the nested X remains a normal vanilla-style outlined button.
- `array_pos(array, value) >= 0` is not a safe membership test in this runtime. When the value is absent, `array_pos` throws `value was not found in array` instead of returning `-1`. The first in-game Quest Log test captured this at `QuestPins.gml:172`. Membership checks use `array_contains`; `array_pos` is now called only after presence is established or when the element is structurally guaranteed to be a child of the target scroller.
- Passing a local anonymous callback into a helper and reading outer local variables from that callback is unsafe in this runtime. Quest Pins 0.1.1 captured `_relevant` this way; at execution the VM looked for it as an object field and threw `no such field "_relevant"`. Version 0.1.2 replaces the callback traversal with an explicit array of requirement structs and ordinary loops.

## Automated validation

The official MOMI 0.15.6 CLI was run against the installable directory and the pristine game 1.0.4 backup:

```powershell
ModsOfMistriaInstaller-cli.exe --lint .\quest_pins C:\path\to\assets.bak.zip --strict-lints --compile-check require
```

Latest result for version 0.1.10:

```text
lint chikedor.quest_pins v0.1.10
  gml: 1 file(s) installing under scripts/chikedor_quest_pins/
  RESULT: OK - the apply would install this mod
```

A real MOMI 0.15.5 apply with Find My Mistrian and Quest Pins enabled passed the compile gate (`100` seamed/framework files plus one GML file for each mod) and reported `2 mod(s) installed`, including Quest Pins 0.1.5.

A real MOMI 0.15.6 apply on 2026-08-20 against Fields of Mistria 1.0.4 build 24820767 passed the compile gate (`103` seamed/framework files plus one GML file for each installed mod) and reported `3 mod(s) installed`, including Quest Pins 0.1.8. The final `assets.zip` SHA-256 was `3d0897823962ed3cbe80603d2edc972a9ddef20076fa7f9318259679e36b1e3d`; its `assets/gml/scripts/chikedor_quest_pins/QuestPins.gml` SHA-256 was `6046a1c25760d73c5d47c281835b65ce495b53194e1a28478f2bba1981c7821c`, exactly matching the validated repository source.

A real MOMI 0.15.6 apply on 2026-08-21 against the same supported game build passed the compile gate and installed Quest Pins 0.1.9 alongside the other two enabled mods. The final `assets.zip` SHA-256 was `4574a644286929c7d9768c3e24ef24f926aed7c107324db1cd980a4f8960774a`; its Quest Pins GML SHA-256 was `0bf1c4279e8ad9f6d1d28814c1dcb6a46949194c450b2e199e46cd781e1c0023`, exactly matching both the repository source and installed mod copy.

The first MOMI 0.15.6 apply of Quest Pins 0.1.10 on 2026-08-24 passed the compile gate and produced `assets.zip` SHA-256 `ac4534cdcf48a1e8315220727a7cdb6f34c5d210c0f2111531704b98bce9113f`, with matching Quest Pins GML SHA-256 `eafd1b3b64bf87c6a47cc2b5007de807e39b53628398e71c1b218b7f6af78213`. This build is rejected: the first in-game run proved that `add_hover_outline()` was unavailable on the positional card root, so MMAPI aborted Quest Pins initialization and rendered no pinned quests. It must not be treated as a known-good 0.1.10 build.

The corrected MOMI 0.15.6 apply on 2026-08-24 removed that incompatible outline call, passed the compile gate, and installed Quest Pins 0.1.10 alongside the other two enabled mods. The final `assets.zip` SHA-256 was `fea80812d33128078a83de332001878619355aa4307fdfb331b19dc5af459673`; its Quest Pins GML SHA-256 was `bd32e6969680052dff177899a75e64f5af8d73ca2e6a1c721517eea7e5bd21e0`, exactly matching both the corrected repository source and installed mod copy. In-game regression of card rendering, card navigation, and X priority remains required before publication.

The subsequent 0.1.10 UI candidate on 2026-08-24 additionally aligned supplemental chest stock beneath item names, normalized Journal source-icon sizing, and added pinned-state indicators. MOMI 0.15.6 again passed the compile gate. The final `assets.zip` SHA-256 was `71d5655d005426d7ca62cc32eba3207723a51c5b5209a54aceefcc6e83b7c64c`; its Quest Pins GML SHA-256 was `8e92faf12e1b99a0a676f2d665601b7d5dd20756866c90e6130842cf02b7165a`, exactly matching both the repository source and installed mod copy. This candidate still requires in-game layout and interaction regression before publication.

The compact chest-stock UI candidate on 2026-08-24 replaced the localized `Chest: N` label with a dedicated 14-pixel row containing only the vanilla storage icon and `xN` in the standard readable LUT. MOMI 0.15.6 strict lint and required compilation passed. The final `assets.zip` SHA-256 was `e786fb6cdd4fdda53ba573154ade42bc7cff6600fa7171ef4cd5d43dfc6ceb75`; its Quest Pins GML SHA-256 was `13d44aa9bf0c6c6b176a83c038f605305c56f9f4b349398ce8494dbaa3686231`, exactly matching the repository source, installed mod copy, and compiled archive entry. Native-resolution visual regression remains required before this candidate becomes known-good.

The unified source-row candidate on 2026-08-24 applied the same icon-plus-`xN` contract to backpack and chest stock, aligned every source icon with the requirement icon, and allocated exactly 14 pixels per visible source. MOMI 0.15.6 strict lint and required compilation passed. The final `assets.zip` SHA-256 was `7a42da8184e5d2c69e0e11c1846db5adb07de13ca5310b8ac3043a15dffea40e`; its Quest Pins GML SHA-256 was `dee8b5df313ae60a52b0a0e84f3f71f28cf5ed93d8ea1b5280abd8950cb5a968`, exactly matching the repository source, installed mod copy, and compiled archive entry. Automated geometry checks covered zero, one, and two source rows and one-, two-, and three-digit counts. The attempted native-resolution visual run could not start because Windows app-control authorization timed out, so in-game regression remains required.

The single-line multi-source candidate on 2026-08-24 keeps backpack and chest stock in the same 14-pixel secondary row. Backpack remains first; the chest icon anchors eight pixels after the rendered backpack count, so one-, two-, and three-digit values cannot collide and no fixed text-width estimate is involved. MOMI 0.15.6 strict lint and required compilation passed. The final `assets.zip` SHA-256 was `381d9fbf68dd1f30568f311cefef5f6f6a2d07d4f64947ce8de7afe220f8957c`; its Quest Pins GML SHA-256 was `a34c193c2d28b391c8df8eaa31e3c27fd91995bff1d444224e73ed425a85ef9f`, exactly matching the repository source, installed mod copy, and compiled archive entry. In-game layout regression remains required before publication.

The centered-column candidate on 2026-08-24 corrects the visual-axis mismatch exposed by the annotated in-game screenshot. Vanilla requirement labels are children of item sprites, so differing sprite bounds previously shifted both icon centers and label starts. The candidate centers every main and secondary sprite inside an identical 20-pixel slot at row X=2 and compensates the vanilla child-label offset to start after that slot. MOMI 0.15.6 strict lint and required compilation passed. The final `assets.zip` SHA-256 was `c91f57d21019e7a60c2feea949b9ca3eb51d234176c79566e6dc160276d273ca`; its Quest Pins GML SHA-256 was `481cf647970825f2ac562df13599e4ffb79d0a09642103b1ef8c24ac0240e397`, exactly matching the repository source, installed mod copy, and compiled archive entry. The user subsequently confirmed the corrected in-game layout.

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

Validated in game on 2026-08-19 for Quest Pins 0.1.7:

- A mine-seal mission using `Requirement.SuppliedItems` renders all four vanilla item rows in its pinned HUD card.
- The header X unpins a quest directly from the HUD and resolves through localization without displaying `MISSING`.
- Long requirement names remain on one line, and the revised 112–208 pixel width presets retain the standard game font while keeping narrow cards shorter through measured objective-line limits.

Validated in game on 2026-08-20 for Quest Pins 0.1.8 with Fields of Mistria 1.0.4 build 24820767 and MOMI/MMAPI 0.15.6:

- A donation-box objective keeps its main counter tied to deposited progress while independently showing live `Mochila` and `Cofre` quantities for the same required items.
- Spanish source labels and values share or stack within the measured row width without overlapping the item name or authoritative counter; long item names remain single-line and ellipsized.
- The captured HUD state under `docs/images/deliverables-backpack-chest.png` records this verified behavior on the supported patch.

Validated in game on 2026-08-24 for Quest Pins 0.1.10 with the same supported game build and MOMI/MMAPI 0.15.6:

- Backpack and chest quantities share one compact secondary row below their requirement, with backpack first and a stable gap before chest stock.
- Main item, backpack, and chest sprites are visually centered on the same fixed icon axis despite their different sprite bounds.
- Item labels and `xN` values begin after the shared icon column, and consecutive requirements remain visually separated without unused vertical rows.
