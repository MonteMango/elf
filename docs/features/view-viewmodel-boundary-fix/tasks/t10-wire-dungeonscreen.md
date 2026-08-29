---
id: T10
title: "Wire DungeonScreen to call viewModel.finishRun() instead of gameSession.finishDungeonRun()+saveInBackground()"
layer: "ui"
deps: ["T3"]
acs: ["AC-03", "AC-04"]
files_hint: ["Packages/elf_iOS/Sources/Screens/DungeonScreen/DungeonScreen.swift"]
owner: "Vitalii Lytvynov"
estimate: "S"
status: "todo"
---

# T10 — Wire DungeonScreen to call viewModel.finishRun()

## Why

`DungeonScreen.swift:93,95` calls `gameSession.finishDungeonRun()` + `.saveInBackground()` directly from a private method — [spec §1](../spec.md), [spec §7 KPI baseline](../spec.md). Reuses the existing route/navigation setup — no new UI component.

## What

Replace the direct `gameSession.finishDungeonRun()` + `.saveInBackground()` calls with `viewModel.finishRun()` (from T3). Preserve the existing order exactly: `router.popToGameDay()` executes synchronously **before** the finish call — no `await` may sit between pop and session release, per [sad §6 Flow 2](../sad.md).

## Definition of Done

- [ ] `DungeonScreen.swift` contains no direct `GameSession` mutation.
- [ ] `router.popToGameDay()` still runs before `viewModel.finishRun()`, with no `await` in between.
- [ ] Build succeeds (`xcodebuild -scheme elf -destination 'platform=iOS Simulator,name=iPhone 17' build`).

## Notes

Depends on T3. Pure call-site swap, but the pop-before-release ordering is load-bearing — do not reorder.
