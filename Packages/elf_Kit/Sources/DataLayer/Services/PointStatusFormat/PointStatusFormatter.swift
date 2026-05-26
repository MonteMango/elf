//
//  PointStatusFormatter.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Renders `PointStatus` cases into human-readable strings for two distinct
/// surfaces:
///   - `shortLabel(for:)` — terse overlay text on a body part during combat
///     (e.g. `"crit 25"`, `"block"`, `"weak 7"`, `"dodge"`). Returns `nil` for
///     `.nothing` so the View can skip rendering altogether.
///   - `debugLine(for:)` — verbose console-log line with component breakdown
///     (e.g. `"💥 HIT (12 damage: weapon=10 str=5 end_red=0 armor=3)"`).
///
/// The displayed damage number ALWAYS comes from `PointStatus.damageTakenValue`,
/// keeping a single source of truth: if the production damage formula shifts,
/// only `damageTakenValue` and the formatter's text composition need to be
/// touched — never call-sites.
public protocol PointStatusFormatter: Sendable {

    func shortLabel(for status: PointStatus) -> String?

    func debugLine(for status: PointStatus) -> String
}
