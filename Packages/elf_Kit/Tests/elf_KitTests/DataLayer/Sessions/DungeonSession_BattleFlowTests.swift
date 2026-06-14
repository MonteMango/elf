//
//  DungeonSession_BattleFlowTests.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import XCTest
@testable import elf_Kit

/// Tests for the dungeon run's battle-flow state on `DungeonSession`:
/// vitals seeding (`beginRun`), folding a finished battle back in
/// (`applyBattleOutcome`), the room-to-room 25% heal (`restoreQuarter`), and
/// linear room advancement (`moveSquadToNextRoom`).
@MainActor
final class DungeonSession_BattleFlowTests: XCTestCase {

    // MARK: - Fixtures

    private let dungeonId = DungeonID(rawValue: UUID())
    private let roomAId = DungeonRoomID(rawValue: UUID())
    private let roomBId = DungeonRoomID(rawValue: UUID())

    /// Two-room linear dungeon: A (combat) → B (boss, final).
    private struct FakeDungeonRepository: DungeonRepository {
        let dungeon: Dungeon
        func getAll() -> [Dungeon] { [dungeon] }
        func getById(id: DungeonID) -> Dungeon? { id == dungeon.id ? dungeon : nil }
        func randomDungeon() -> Dungeon? { dungeon }
    }

    private func makeDungeon() -> Dungeon {
        let roomB = DungeonRoom(
            id: roomBId, title: "Boss Hall", kind: .boss([]), nextRoomIds: []
        )
        let roomA = DungeonRoom(
            id: roomAId, title: "Entry", kind: .combat([]), nextRoomIds: [roomBId]
        )
        return Dungeon(
            id: dungeonId, title: "Test Dungeon", description: "",
            type: .onePath, world: .upper, backgroundImageName: "bg",
            entryRoomIds: [roomAId], rooms: [roomA, roomB]
        )
    }

    private func makeOneHandedWeapon() -> ElfOneHandedWeaponItem {
        // swiftlint:disable:next force_try
        let item = try! TestFixtures.weaponItem(
            id: UUID(), title: "Test Sword", handUse: .oneHand,
            minimumAttackPoint: 5, maximumAttackPoint: 10, epBlockCost: 200
        )
        guard let oneHanded = ElfOneHandedWeaponItem(weapon: ElfWeaponItem(weaponItem: item)) else {
            fatalError("Test fixture weapon must be one-handed")
        }
        return oneHanded
    }

    private func makeElf(hp: Int16, mp: Int16) -> ElfInfo {
        let attrs = HeroAttributes(
            hitPoints: Attribute(hp), manaPoints: Attribute(mp), agility: 1,
            strength: 1, power: 1, instinct: 1, endurance: 0
        )
        return ElfInfo(
            name: "Elf",
            imageName: "elf_1",
            fightStyle: .dodge,
            currentExp: 0,
            fightStyleAttributes: attrs,
            randomLevelAttributes: HeroAttributes(),
            equipped: EquippedItems(weapons: .oneHanded(weapon: makeOneHandedWeapon())),
            inventory: ElfInventory()
        )
    }

    /// Builds a session + dungeon session with a fresh hero and one ally.
    private func makeSession() -> (DungeonSession, hero: ElfInfo, ally: ElfInfo) {
        let hero = makeElf(hp: 100, mp: 40)
        let ally = makeElf(hp: 80, mp: 20)
        let others = (0..<(House.membersCount - 2)).map { _ in makeElf(hp: 50, mp: 10) }
        let members = [hero, ally] + others
        let houses: [House] = (0..<Game.housesCount).map { i in
            House(name: "H\(i)", logoImageName: "logo", members: members)
        }
        let calendar = [GameDay(dayNumber: 1, dayType: .normal)]
        let game = Game(
            houses: houses,
            gameState: GameState(currentDay: calendar[0], calendar: calendar),
            playerHouseIndex: 0,
            playerMemberIndex: 0
        )
        let store = GameStore(from: game)
        let session = withDependencies {
            $0.dungeonRepository = FakeDungeonRepository(dungeon: makeDungeon())
        } operation: {
            DungeonSession(gameStore: store, dungeonId: dungeonId, allyIds: [ally.id])
        }
        return (session, hero, ally)
    }

    /// Minimal player-side snapshot — `applyBattleOutcome` only reads
    /// `source`, `currentHP`, `currentMP`.
    private func snapshot(elfId: ElfID, hp: Int, mp: Int) -> CombatantSnapshot {
        CombatantSnapshot(
            source: .elf(elfId),
            name: "Elf", imageName: "elf_1", combatantType: .elf,
            currentHP: hp, currentMP: mp, currentEP: 0, maxEP: 0,
            baseHeroAttributes: HeroAttributes(),
            attacks: [], defensePoints: 0, armorValues: [:]
        )
    }

    // MARK: - beginRun

    func testBeginRun_SeedsFullVitalsForHeroAndAlly() {
        let (session, hero, ally) = makeSession()

        session.beginRun()

        XCTAssertEqual(session.roomVitals[hero.id], DungeonElfVitals(hp: 100, mp: 40))
        XCTAssertEqual(session.roomVitals[ally.id], DungeonElfVitals(hp: 80, mp: 20))
        XCTAssertEqual(session.currentRoom?.id, roomAId)
        XCTAssertFalse(session.isCurrentRoomCleared)
    }

    // MARK: - applyBattleOutcome

    func testApplyBattleOutcome_HeroSurvives_UpdatesVitalsAndClearsRoom() {
        let (session, hero, ally) = makeSession()
        session.beginRun()

        session.applyBattleOutcome(
            finalLeftTeam: [
                snapshot(elfId: hero.id, hp: 30, mp: 5),
                snapshot(elfId: ally.id, hp: 0, mp: 0)
            ],
            outcome: .victory
        )

        XCTAssertEqual(session.roomVitals[hero.id], DungeonElfVitals(hp: 30, mp: 5))
        XCTAssertEqual(session.roomVitals[ally.id], DungeonElfVitals(hp: 0, mp: 0))
        XCTAssertFalse(session.heroIsDowned)
        XCTAssertTrue(session.isCurrentRoomCleared)
    }

    func testApplyBattleOutcome_HeroDowned_DoesNotClearRoom() {
        let (session, hero, ally) = makeSession()
        session.beginRun()

        session.applyBattleOutcome(
            finalLeftTeam: [
                snapshot(elfId: hero.id, hp: 0, mp: 0),
                snapshot(elfId: ally.id, hp: 10, mp: 0)
            ],
            outcome: .defeat
        )

        XCTAssertTrue(session.heroIsDowned)
        XCTAssertFalse(session.isCurrentRoomCleared)
    }

    func testApplyBattleOutcome_NegativeHPClampedToZero() {
        let (session, hero, _) = makeSession()
        session.beginRun()

        session.applyBattleOutcome(
            finalLeftTeam: [snapshot(elfId: hero.id, hp: -25, mp: -3)],
            outcome: .defeat
        )

        XCTAssertEqual(session.roomVitals[hero.id], DungeonElfVitals(hp: 0, mp: 0))
    }

    // MARK: - restoreQuarter

    func testRestoreQuarter_HealsLivingByQuarterAndClampsToMax() {
        let (session, hero, _) = makeSession()
        session.beginRun()
        // Hero down to 30/100 HP, 5/40 MP.
        session.applyBattleOutcome(
            finalLeftTeam: [snapshot(elfId: hero.id, hp: 30, mp: 5)],
            outcome: .victory
        )

        session.restoreQuarter()

        // +25% of max → +25 HP, +10 MP.
        XCTAssertEqual(session.roomVitals[hero.id], DungeonElfVitals(hp: 55, mp: 15))
    }

    func testRestoreQuarter_DoesNotReviveDownedMembers() {
        let (session, _, ally) = makeSession()
        session.beginRun()
        session.applyBattleOutcome(
            finalLeftTeam: [snapshot(elfId: ally.id, hp: 0, mp: 0)],
            outcome: .victory
        )

        session.restoreQuarter()

        XCTAssertEqual(session.roomVitals[ally.id], DungeonElfVitals(hp: 0, mp: 0))
    }

    func testRestoreQuarter_ClampsAtMax() {
        let (session, hero, _) = makeSession()
        session.beginRun() // hero starts full at 100/40

        session.restoreQuarter()

        XCTAssertEqual(session.roomVitals[hero.id], DungeonElfVitals(hp: 100, mp: 40))
    }

    // MARK: - apply(_:) — healing-spring outcome

    func testApplyHealingSpring_FullyRestoresLivingAndClearsRoom() {
        let (session, hero, ally) = makeSession()
        session.beginRun()
        // Knock both down to partial reserves (room not cleared by this).
        session.applyBattleOutcome(
            finalLeftTeam: [
                snapshot(elfId: hero.id, hp: 10, mp: 2),
                snapshot(elfId: ally.id, hp: 5, mp: 1)
            ],
            outcome: .draw
        )

        session.apply(DungeonEventOutcome(restore: .full, clearsRoom: true))

        XCTAssertEqual(session.roomVitals[hero.id], DungeonElfVitals(hp: 100, mp: 40))
        XCTAssertEqual(session.roomVitals[ally.id], DungeonElfVitals(hp: 80, mp: 20))
        XCTAssertTrue(session.isCurrentRoomCleared)
    }

    func testApplyHealingSpring_DoesNotReviveDownedMembers() {
        let (session, hero, ally) = makeSession()
        session.beginRun()
        session.applyBattleOutcome(
            finalLeftTeam: [
                snapshot(elfId: hero.id, hp: 30, mp: 5),
                snapshot(elfId: ally.id, hp: 0, mp: 0)
            ],
            outcome: .victory
        )

        session.apply(DungeonEventOutcome(restore: .full, clearsRoom: true))

        XCTAssertEqual(session.roomVitals[hero.id], DungeonElfVitals(hp: 100, mp: 40))
        XCTAssertEqual(session.roomVitals[ally.id], DungeonElfVitals(hp: 0, mp: 0))
    }

    // MARK: - moveSquadToNextRoom

    func testMoveSquadToNextRoom_AdvancesEveryoneAndExposesFinalRoom() {
        let (session, hero, ally) = makeSession()
        session.beginRun()

        session.moveSquadToNextRoom()

        XCTAssertEqual(session.currentRoom?.id, roomBId)
        XCTAssertEqual(session.elfLocations[hero.id], roomBId)
        XCTAssertEqual(session.elfLocations[ally.id], roomBId)
        XCTAssertFalse(session.hasNextRoom) // room B is final
    }
}
