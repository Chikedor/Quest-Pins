# Repository instructions

## Project

- Mod: `Quest Pins`
- Installable directory: `quest_pins`
- Supported game version: `Fields of Mistria 1.0.3 (Steam build 24742087)`
- Supported MOMI/MMAPI version: `0.15.5 (v0.15.5, 9b90ee213309e7aaca5870ac43272682b6f595ad)`

Before changing code, read this file, `README.md`, `RESEARCH.md`, and the sibling `Modding Knowledge/` project.

## Rules

- Keep this mod independent from other mod repositories.
- Prefer authoritative structured quest and inventory state over localized-text parsing.
- Verify uncertain engine/MMAPI behavior from source, extracted assets, or runtime diagnostics.
- Preserve vanilla saves and progression.
- Keep hooks and UI additions idempotent and restore vanilla properties changed temporarily.
- Add targeted opt-in diagnostics before guessing at intermittent bugs.
- Put reusable verified findings in the sibling `Modding Knowledge/` base and mod-specific findings in `RESEARCH.md`.
- Run MOMI strict lint and required compile checks, then test the supported scenario in game.
- Commit and push every known-good milestone to GitHub.
- If an approach fails, return to the previous known-good commit and try another approach.

## Completion

A change is complete only when the supported scenario works in game, validation passes, documentation matches reality, and the known-good state is committed and published.
