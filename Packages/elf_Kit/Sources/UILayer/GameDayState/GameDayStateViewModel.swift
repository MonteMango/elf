//
//  GameDayStateViewModel.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Shared view model for the current-day state (action points, calendar position,
/// next-day transition). One instance is owned by `AppCoordinator` for the
/// duration of a game session and injected into the view tree by
/// `SessionRouteView` via `.environment(...)`. In-game screens read it through
/// `@Environment(GameDayStateViewModel.self)`.
@MainActor
@Observable
public final class GameDayStateViewModel {

    // MARK: - Dependencies

    /// Weak ref so the VM doesn't keep `GameSession` alive past `endGame()`.
    /// `session` outlives any view that observes this VM (coordinator releases
    /// both together), so unwrap-on-read is safe in practice.
    private weak var session: GameSession?

    // MARK: - State (read through the session's store)

    public var actionPoints: ActionPoints {
        session?.state.actionPoints ?? ActionPoints.unsafeCreate(current: 0, maximum: 0)
    }

    public var currentDay: GameDay {
        session?.state.currentDay ?? GameDay(dayNumber: 1, dayType: .normal)
    }

    public var upcomingDays: [GameDay] {
        session?.state.upcomingDays ?? []
    }

    public var calendar: [GameDay] {
        session?.state.calendar ?? []
    }

    public var isLastDay: Bool {
        session?.state.isLastDay ?? false
    }

    // MARK: - Initialization

    public init(session: GameSession) {
        self.session = session
    }

    // MARK: - Actions

    public func advanceToNextDay() async {
        guard let session else { return }
        session.advanceToNextDay()
        try? await session.save()
    }

    public func spendActionPoints(_ amount: Int) {
        session?.spendActionPoints(amount)
    }
}
