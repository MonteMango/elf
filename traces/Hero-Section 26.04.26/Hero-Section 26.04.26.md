# HeroSection trace — 2026-04-26

## Files

- `Hero-Section.before.1.trace`
- `Hero-Section.before.2.trace`

Both are recordings of the same session. Pre-fix (before the `UIImage(named:)` cleanup and reusable `ItemIconImage` refactor).

## Recording metadata

| | |
|---|---|
| Recorded at | 2026-04-26 01:36 |
| Template | SwiftUI |
| Recording duration | 20.58 s |
| Build | TBD (Debug or Release) |
| Device | TBD |
| iOS version | TBD |
| Equipped slots before recording | TBD (out of 11) |

## Scenario

1. Start app
2. Main menu
3. Continue
4. GameDayScreen
5. Equip helmet
6. Unequip
7. Equip
8. Unequip
9. Equip

5 equip/unequip transitions on the helmet slot. All other equipment slots and stats untouched during the recording.

## Findings (from `analyze_trace.py`)

- `HeroSection.body`: 5.62 ms total / 5 invocations / 1.12 ms avg.
- 1 hitch (33 ms) at 4751 ms, correlates with `CALayer copyRenderLayer` — not with `HeroSection`.
- 0 hangs.
- `assetForName:` / `imageNamed:` not present in Time Profiler hot frames.
- Top invalidation source for `HeroSection.body`: `GeometryReader<ModifiedContent>.Child` in a parent `GeometryReader<HStack, _PaddingLayout>` (4 of 5 edges). The 5th edge is `_ConditionalContent` (the inventory sheet show/hide).

## Conclusion

`UIImage(named:)` in `HeroSection.body` was suspected as a perf hotspot. Trace did not confirm. Cleanup is hygiene only, not a perf fix.
