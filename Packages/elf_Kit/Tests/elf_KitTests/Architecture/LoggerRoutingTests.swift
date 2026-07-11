//
//  LoggerRoutingTests.swift
//  elf_KitTests
//
//  Created by Vitalii Lytvynov
//

import XCTest

/// T4 (architecture-hardening, AC-02): the 9 confirmed raw-`print(` sites in
/// `CharacterCreationViewModel`, `GameDayViewModel`,
/// `DefaultDungeonRewardCalculator` and `GameSession` must be routed through
/// the `debugGameLogger`/`debugBattleLogger` dependency instead.
///
/// This is a source-content check (matching the AC-08 doc-consistency
/// convention in this feature's test plan) rather than a behavioural test —
/// the DoD is literally "0 raw `print(` calls remain" plus "gained a logger
/// dependency", which are properties of the source text, not of runtime
/// output.
final class LoggerRoutingTests: XCTestCase {

    /// `elf_Kit/Sources/...` root, resolved relative to this test file so it
    /// works regardless of the machine's checkout path.
    private var sourcesRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // Architecture/
            .deletingLastPathComponent() // elf_KitTests/
            .deletingLastPathComponent() // Tests/
            .deletingLastPathComponent() // elf_Kit/
            .appendingPathComponent("Sources")
    }

    private func contents(_ relativePath: String) throws -> String {
        let url = sourcesRoot.appendingPathComponent(relativePath)
        return try String(contentsOf: url, encoding: .utf8)
    }

    private let targetFiles: [String] = [
        "UILayer/CharacterCreation/CharacterCreationViewModel.swift",
        "UILayer/GameDay/GameDayViewModel.swift",
        "DataLayer/Services/Dungeon/Implementation/DefaultDungeonRewardCalculator.swift",
        "DataLayer/Sessions/GameSession.swift"
    ]

    /// No raw `print(` call may remain in any of the 4 files T4 targets.
    func test_noRawPrintCallsRemainInTargetFiles() throws {
        for relativePath in targetFiles {
            let source = try contents(relativePath)
            let rawPrintLines = source
                .components(separatedBy: .newlines)
                .filter { $0.contains("print(") }
            XCTAssertTrue(
                rawPrintLines.isEmpty,
                "\(relativePath) still contains raw print( call(s): \(rawPrintLines)"
            )
        }
    }

    /// `CharacterCreationViewModel`, `GameDayViewModel` and
    /// `DefaultDungeonRewardCalculator` had no logger dependency before T4 —
    /// each must now inject `debugGameLogger` or `debugBattleLogger`.
    func test_previouslyLoggerlessTypesNowInjectALogger() throws {
        let filesRequiringNewLoggerDependency: [String] = [
            "UILayer/CharacterCreation/CharacterCreationViewModel.swift",
            "UILayer/GameDay/GameDayViewModel.swift",
            "DataLayer/Services/Dungeon/Implementation/DefaultDungeonRewardCalculator.swift"
        ]

        for relativePath in filesRequiringNewLoggerDependency {
            let source = try contents(relativePath)
            let injectsGameLogger = source.contains("Dependency(\\.debugGameLogger)")
            let injectsBattleLogger = source.contains("Dependency(\\.debugBattleLogger)")
            XCTAssertTrue(
                injectsGameLogger || injectsBattleLogger,
                "\(relativePath) does not inject \\.debugGameLogger or \\.debugBattleLogger"
            )
        }
    }

    // MARK: - T24 (review finding #7): logDebug for non-error traces, sink-side #if DEBUG

    /// `DebugGameLogger` must expose a non-error `logDebug(_:)` for
    /// informational traces, alongside the existing `logError(_:)`.
    func test_debugGameLoggerDeclaresLogDebug() throws {
        let source = try contents("DataLayer/Services/Logging/DebugGameLogger.swift")
        XCTAssertTrue(
            source.contains("func logDebug(_ message: String)"),
            "DebugGameLogger must declare logDebug(_:) for non-error traces"
        )
    }

    /// The success trace in `CharacterCreationViewModel.createCharacter()` and
    /// the 3 UI-tap traces in `GameDayViewModel` are not errors — they must
    /// route through `logDebug`, not `logError`.
    func test_nonErrorTracesRouteThroughLogDebugNotLogError() throws {
        let characterCreation = try contents("UILayer/CharacterCreation/CharacterCreationViewModel.swift")
        XCTAssertTrue(
            characterCreation.contains(#"debugGameLogger.logDebug("✅ Character created:"#),
            "CharacterCreationViewModel's success trace must route through logDebug, not logError"
        )

        let gameDay = try contents("UILayer/GameDay/GameDayViewModel.swift")
        for expectedCall in [
            #"debugGameLogger.logDebug("Action tapped:"#,
            #"debugGameLogger.logDebug("Side menu tapped:"#,
            #"debugGameLogger.logDebug("Pocket tapped:"#
        ] {
            XCTAssertTrue(
                gameDay.contains(expectedCall),
                "GameDayViewModel's UI-tap trace must route through logDebug, not logError: \(expectedCall)"
            )
        }
    }

    /// The `#if DEBUG` guard for `logError`/`logDebug` output lives at the
    /// sink (`ConsoleDebugGameLogger`), not at each call site — so the
    /// now-redundant call-site guards in `GameSession` and
    /// `DefaultDungeonRewardCalculator` are removed.
    func test_sinkGuardsDebugOutput_callSitesDoNotDuplicateTheGuard() throws {
        let console = try contents("DataLayer/Services/Logging/Implementation/ConsoleDebugGameLogger.swift")
        XCTAssertTrue(
            console.contains("#if DEBUG"),
            "ConsoleDebugGameLogger must gate logError/logDebug output in #if DEBUG at the sink"
        )

        let gameSession = try contents("DataLayer/Sessions/GameSession.swift")
        XCTAssertFalse(
            gameSession.contains("#if DEBUG") && gameSession.contains("logError"),
            "GameSession's logError call site no longer needs its own #if DEBUG guard — the sink gates it"
        )

        let dungeonRewardCalculator = try contents(
            "DataLayer/Services/Dungeon/Implementation/DefaultDungeonRewardCalculator.swift"
        )
        XCTAssertFalse(
            dungeonRewardCalculator.contains("#if DEBUG") && dungeonRewardCalculator.contains("logError"),
            "DefaultDungeonRewardCalculator's logError call site no longer needs its own #if DEBUG guard"
        )
    }
}
