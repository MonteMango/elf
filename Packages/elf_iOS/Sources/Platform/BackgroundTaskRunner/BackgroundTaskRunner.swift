//
//  BackgroundTaskRunner.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import UIKit

/// Runs async work while holding a UIKit background-task assertion, so the system
/// doesn't suspend the process mid-flight. A bare `.background` transition gives
/// only ~5s before suspension; an assertion extends that to ~30s.
///
/// The assertion MUST be acquired synchronously, before the async work is
/// scheduled — callers invoke this from a scene-phase handler, and deferring the
/// assertion past an `await` reopens the very suspension window it exists to close.
///
/// Internal to `elf_iOS`: the only consumer is `AppCoordinator`. Tests reach it
/// via `@testable import elf_iOS` and override `\.backgroundTaskRunner`.
protocol BackgroundTaskRunner: Sendable {
    /// Acquires a named background-task assertion synchronously, then runs `work`
    /// under it and releases the assertion when `work` finishes (or on expiration).
    /// Fire-and-forget: returns immediately after the assertion is taken.
    @MainActor
    func run(name: String, _ work: @escaping @MainActor () async -> Void)
}
