//
//  GameDayStateViewModel.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies
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

    /// Off-main orchestrator for AI elves' turns. `Sendable`, not `@MainActor` —
    /// its `run` executes the bot battles on the cooperative pool.
    private let worldTurnRunner: any WorldTurnRunner

    /// True while a day transition (world turn → apply → save) is in flight.
    /// Guards against a re-entrant "Next day" tap during the off-main await,
    /// which would otherwise run a second world turn over already-mutated state.
    /// Views may also read it to disable the button.
    public private(set) var isAdvancingDay = false

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
        @Dependency(\.worldTurnRunner) var worldTurnRunner
        self.worldTurnRunner = worldTurnRunner
        self.session = session
    }

    // MARK: - Actions

    /// Ends the player's day: runs every AI elf's turn off-main, applies the
    /// combined outcome, advances the calendar (refilling AP and expiring
    /// buffs), and saves.
    ///
    /// Sequencing matters: bots spend the *current* day's AP, so the world turn
    /// runs and applies before `advanceToNextDay()` refills everyone.
    public func advanceToNextDay() async {
        guard let session, !isAdvancingDay else { return }
        isAdvancingDay = true
        defer { isAdvancingDay = false }

        // 1. Snapshot the bots on the main actor (value-type copies, player
        //    excluded). This is the isolation barrier from the observable store.
        let bots = buildBotContexts(session: session)
        let turnSeed = makeTurnSeed(
            gameId: session.state.gameId,
            dayNumber: session.state.currentDay.dayNumber
        )

        // 2. Simulate off-main on the cooperative pool. The await suspends the
        //    main actor without blocking it (no progress overlay by design).
        let outcome = await worldTurnRunner.run(bots: bots, turnSeed: turnSeed)

        // 3. Apply + advance + save, all synchronous on the main actor.
        session.applyWorldTurn(outcome)
        session.advanceToNextDay()
        try? await session.save()
    }

    public func spendActionPoints(_ amount: Int) {
        session?.spendActionPoints(amount)
    }

    // MARK: - Private Helpers

    /// Builds a value-type snapshot of every AI elf to simulate — all roster
    /// members except the player, skipping eliminated houses.
    private func buildBotContexts(session: GameSession) -> [BotTurnContext] {
        let playerHouseIndex = session.state.playerHouseIndex
        let playerMemberIndex = session.state.playerMemberIndex

        var contexts: [BotTurnContext] = []
        for (houseIndex, house) in session.state.houses.enumerated() {
            if house.isEliminated { continue }
            for (memberIndex, elf) in house.members.enumerated() {
                if houseIndex == playerHouseIndex && memberIndex == playerMemberIndex { continue }
                let slot = RosterSlot(houseIndex: houseIndex, memberIndex: memberIndex, id: elf.id)
                contexts.append(BotTurnContext(slot: slot, elf: elf))
            }
        }
        return contexts
    }

    /// Derives the turn's root seed from the game id and day number — stable per
    /// (game, day) so a turn is reproducible, varied across games and days.
    private func makeTurnSeed(gameId: GameID, dayNumber: Int) -> UInt64 {
        let uuid = gameId.rawValue.uuid
        let high = UInt64(uuid.0) << 56 | UInt64(uuid.1) << 48 | UInt64(uuid.2) << 40
            | UInt64(uuid.3) << 32 | UInt64(uuid.4) << 24 | UInt64(uuid.5) << 16
            | UInt64(uuid.6) << 8 | UInt64(uuid.7)
        return high ^ UInt64(bitPattern: Int64(dayNumber))
    }
}
