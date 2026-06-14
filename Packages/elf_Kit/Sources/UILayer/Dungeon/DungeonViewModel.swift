//
//  DungeonViewModel.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import Foundation

/// What the bottom room-action button does in the current room state.
public enum RoomActionKind: Equatable, Sendable {
    /// Start the current room's battle.
    case fight
    /// Drink at a healing spring (event room — still a stub).
    case drink
    /// Advance to the next room (current room cleared, a next room exists).
    case next
    /// Finish the run from a cleared final room.
    case finish
}

/// Drives the parent dungeon-briefing shell: holds the currently-selected
/// segment-control tab and builds the current room's battle / drives the
/// room-to-room transition. Production-derived data (background, entrance
/// enable, dungeon id) is still read directly from the parent `DungeonSession`
/// by the screen — the three tab contents make their own ViewModels from the
/// same session, so this VM only governs the shell's UI state and actions.
@MainActor
@Observable
public final class DungeonViewModel {

    private let session: DungeonSession

    @ObservationIgnored
    @Dependency(\.snapshotBuilder) private var snapshotBuilder

    @ObservationIgnored
    @Dependency(\.progressionService) private var progressionService

    @ObservationIgnored
    @Dependency(\.monsterRepository) private var monsterRepository

    @ObservationIgnored
    @Dependency(\.equippedSlotResolver) private var equippedSlotResolver

    @ObservationIgnored
    @Dependency(\.specialEventResolver) private var specialEventResolver

    // MARK: - View state

    public var activeTab: DungeonTab = .overview

    /// Non-nil while the full-screen transition overlay is showing. The screen
    /// reads this to present `DungeonTransitionView`.
    public private(set) var transition: DungeonTransition?

    /// What the bottom action button does right now. `nil` during the briefing
    /// (Entrance is shown instead). Once a combat room is cleared it flips from
    /// `.fight` to `.next` (or `.finish` on the final room).
    public var actionKind: RoomActionKind? {
        guard let kind = session.currentRoom?.kind else { return nil }
        if session.isCurrentRoomCleared {
            return session.hasNextRoom ? .next : .finish
        }
        switch kind {
        case .combat, .miniBoss, .boss:
            return .fight
        case .event(let event):
            switch event {
            case .healingSpring: return .drink
            }
        }
    }

    /// Bottom action label matching `actionKind`. `nil` during the briefing.
    public var actionTitle: String? {
        switch actionKind {
        case .fight: return "Fight"
        case .drink: return "Drink"
        case .next: return "Next"
        case .finish: return "Finish"
        case nil: return nil
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

    /// Builds the current room's `Battle`: the living squad (carrying their
    /// run HP/MP) versus the room's monsters (expanded by `MonsterRef.count`).
    /// Returns `nil` if there's no current combat room or no resolvable
    /// participants — the screen then does nothing.
    public func startRoomBattle() -> Battle? {
        guard let room = session.currentRoom else { return nil }
        let monsterRefs = room.kind.monsters
        guard !monsterRefs.isEmpty else { return nil }

        var leftTeam: [CombatantSnapshot] = []
        var equipped: [CombatantID: [HeroItemType: HeroEquippedSlot]] = [:]
        for elf in session.squadElves() {
            guard let vitals = session.roomVitals[elf.id], vitals.hp > 0 else { continue }
            var snapshot = snapshotBuilder.buildSnapshot(
                elf: elf,
                level: progressionService.calculateLevel(currentExp: elf.currentExp),
                globalBuffs: elf.globalBuffs
            )
            // The builder seeds full reserves; carry over the run's current HP/MP.
            snapshot.currentHP = min(vitals.hp, snapshot.maxHP)
            snapshot.currentMP = min(vitals.mp, snapshot.maxMP)
            leftTeam.append(snapshot)
            equipped[snapshot.id] = equippedSlotResolver.resolve(equipped: elf.equipped)
        }
        guard !leftTeam.isEmpty else { return nil }

        var rightTeam: [CombatantSnapshot] = []
        for ref in monsterRefs {
            guard let monster = monsterRepository.getById(id: ref.monsterId) else { continue }
            for _ in 0..<max(1, ref.count) {
                rightTeam.append(snapshotBuilder.buildSnapshot(from: monster, globalBuffs: []))
            }
        }
        guard !rightTeam.isEmpty else { return nil }

        return Battle(
            leftTeam: leftTeam,
            rightTeam: rightTeam,
            equippedItemsByCombatantId: equipped
        )
    }

    /// Plays the room-to-room transition: shows the overlay, restores 25% HP/MP
    /// to living members, moves the squad into the next room, then hides the
    /// overlay. Guards against re-entry and against running on an uncleared or
    /// final room. Mirrors the timing of `enterDungeon()`.
    public func advanceToNextRoom() async {
        guard transition == nil,
              session.isCurrentRoomCleared,
              let from = session.currentRoom,
              let nextId = from.nextRoomIds.first,
              let to = session.dungeon?.room(id: nextId) else { return }
        transition = .movingBetweenRooms(from: from.title, to: to.title)
        session.restoreQuarter()
        try? await Task.sleep(for: .seconds(2))
        session.moveSquadToNextRoom()
        transition = nil
    }

    /// Event-room action (e.g. healing-spring "Drink"): resolves the current
    /// room's event to an outcome and applies it (full restore + clear for the
    /// spring). Guarded on the `.drink` state, so a second tap (room already
    /// cleared) is a no-op.
    public func drinkFromSpring() {
        guard actionKind == .drink,
              case .event(let event)? = session.currentRoom?.kind else { return }
        session.apply(specialEventResolver.resolve(event))
    }
}
