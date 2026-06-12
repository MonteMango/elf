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

    /// Non-nil while the full-screen transition overlay is showing. The screen
    /// reads this to present `DungeonTransitionView`.
    public private(set) var transition: DungeonTransition?

    /// Bottom action label for the current room: `Fight` for combat rooms,
    /// the event verb otherwise. `nil` during the briefing (Entrance shown).
    public var actionTitle: String? {
        guard let kind = session.currentRoom?.kind else { return nil }
        switch kind {
        case .combat, .miniBoss, .boss:
            return "Fight"
        case .event(let event):
            switch event {
            case .healingSpring: return "Drink"
            }
        }
    }

    // MARK: - Initialization

    public init(session: DungeonSession) {
        self.session = session
    }

    // MARK: - Actions

    /// Shows the entrance transition overlay for ~2 seconds, then hides it.
    /// Guards against re-entry while a transition is already in flight (e.g.
    /// repeated taps on Entrance). Mirrors the timing approach used by
    /// `FarmActivityViewModel.performActivity()`.
    public func enterDungeon() async {
        guard transition == nil, !session.isInRun else { return }
        let name = session.dungeon?.title ?? "Dungeon"
        transition = .enteringDungeon(name: name)
        try? await Task.sleep(for: .seconds(2))
        session.beginRun()   // swap Overview content to the room behind the overlay
        transition = nil      // overlay fades → room + Fight button revealed
    }

    /// Hook for the next step: starts the current room's battle. No-op for now.
    public func performRoomAction() { }
}
