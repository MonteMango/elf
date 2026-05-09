//
//  GameDayStateViewModel.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Shared view model for the current-day state (action points, calendar position,
/// next-day transition). One instance lives on `GameSession.dayState` for the
/// duration of a game session and is reused by every screen that needs day
/// context (Hunt, Farm, Quest, Craft, GameDay, Dungeon).
@MainActor
@Observable
public final class GameDayStateViewModel {

    // MARK: - Dependencies

    /// Weak ref to break the retain cycle (`session.dayState` ↔ `dayState.session`).
    /// `session` is alive for as long as the game session is active, which is
    /// strictly longer than any view that observes `dayState`.
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
