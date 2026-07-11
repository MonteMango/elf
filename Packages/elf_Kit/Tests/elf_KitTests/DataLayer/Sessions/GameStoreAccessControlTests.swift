//
//  GameStoreAccessControlTests.swift
//  elf_KitTests
//
//  Created by Vitalii Lytvynov
//

import XCTest

/// T23 (architecture-hardening review finding #3): `GameStore.player`'s setter
/// must be `internal`, matching `currentDay`/`calendar`/`houses`/`actionPoints`
/// — a UI-layer (`elf_iOS`) write through `store.player.X = Y` must not
/// compile. This is a source-content check (matching the AC-08/T4
/// doc-consistency convention in this feature's test plan) since Swift has no
/// runtime way to assert "this line doesn't compile from another module" —
/// the DoD is a property of the source text.
final class GameStoreAccessControlTests: XCTestCase {

    private var sourcesRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // Sessions/
            .deletingLastPathComponent() // DataLayer/
            .deletingLastPathComponent() // elf_KitTests/
            .deletingLastPathComponent() // Tests/
            .deletingLastPathComponent() // elf_Kit/
            .appendingPathComponent("Sources")
    }

    private func contents(_ relativePath: String) throws -> String {
        let url = sourcesRoot.appendingPathComponent(relativePath)
        return try String(contentsOf: url, encoding: .utf8)
    }

    func test_playerSetterIsInternal() throws {
        let source = try contents("DataLayer/Sessions/GameStore.swift")
        XCTAssertTrue(
            source.contains("public internal(set) var player:"),
            "GameStore.player must be declared `public internal(set)`, matching currentDay/calendar/houses/actionPoints"
        )
    }
}
