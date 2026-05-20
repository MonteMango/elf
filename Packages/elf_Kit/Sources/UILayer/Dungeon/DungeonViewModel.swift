//
//  DungeonViewModel.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Drives the parent dungeon-briefing shell: holds the currently-selected
/// segment-control tab. Production-derived data (background, entrance enable,
/// dungeon id) is still read directly from the parent `DungeonSession` by the
/// screen — the three tab contents make their own ViewModels from the same
/// session, so this VM only governs the shell's UI state.
@MainActor
@Observable
public final class DungeonViewModel {

    private let session: DungeonSession

    // MARK: - View state

    public var activeTab: DungeonTab = .overview

    // MARK: - Initialization

    public init(session: DungeonSession) {
        self.session = session
    }
}
