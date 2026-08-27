//
//  BattleFightViewModel_DeathRewardBankingTests.swift
//  elf_KitTests
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import XCTest
@testable import elf_Kit

/// AC-04 / AC-07 for T5: `BattleFightViewModel.finishBattle()` must bank
/// dungeon rewards on hero death, and checkpoint-save in every case.
///
/// Proven against a real `GameSession` (its persistence + dungeon-lifecycle
/// dependencies are injected spies) rather than a mock VM collaborator, so
/// the assertions exercise the actual call the DoD names:
/// `session.bankDungeonRewardsOnDeath()` then `session.saveInBackground()`
/// when the hero is downed; save-only (no bank) when the hero survives.
/// Call *order* is captured via a shared sequence log, since AC-04 requires
/// banking before the checkpoint save lands.
@MainActor
final class BattleFightViewModel_DeathRewardBankingTests: XCTestCase {

    // MARK: - Spies

    private final class CallSequenceLog: @unchecked Sendable {
        private(set) var events: [String] = []
        func record(_ event: String) { events.append(event) }
    }

    private final class SpyDungeonLifecycleMutator: DungeonLifecycleMutator, @unchecked Sendable {
        let log: CallSequenceLog
        var bankDungeonRewardsOnDeathCallCount = 0

        init(log: CallSequenceLog) { self.log = log }

        func startDungeonSession(gameStore: GameStore, dungeonId: DungeonID, allyIds: [ElfID]) -> DungeonSession {
            DungeonSession(gameStore: gameStore, dungeonId: dungeonId, allyIds: allyIds)
        }

        func releaseDungeonSession() -> DungeonSession? { nil }

        func flushRewards(from dungeonSession: DungeonSession, into gameStore: GameStore) {}

        func bankDungeonRewardsOnDeath(dungeonSession: DungeonSession?, into gameStore: GameStore) {
            bankDungeonRewardsOnDeathCallCount += 1
            log.record("bank")
        }

        func finishDungeonRun(dungeonSession: DungeonSession?, into gameStore: GameStore) -> DungeonSession? { nil }

        func discardDungeonRun() -> DungeonSession? { nil }
    }

    private final class SpyGameSaveStorage: GameSaveStorage, @unchecked Sendable {
        let log: CallSequenceLog
        var saveCallCount = 0

        init(log: CallSequenceLog) { self.log = log }

        func save(_ game: Game, dungeonRun: DungeonRunSaveData?, slotId: String, playTime: TimeInterval) async throws {
            saveCallCount += 1
            log.record("save")
        }

        func load(slotId: String) async throws -> LoadedSave { fatalError("unused") }
        func hasAnySave() -> Bool { false }
        func getPlayTime(slotId: String) async -> TimeInterval { 0 }
    }

    // MARK: - Fixtures

    private func makeCombatant(currentHP: Int) -> CombatantSnapshot {
        CombatantSnapshot(
            id: CombatantID(),
            source: .synthetic,
            name: "Hero",
            imageName: "img",
            combatantType: .elf,
            level: 1,
            currentHP: currentHP,
            currentMP: 0,
            currentEP: GameMechanicsConstants.startingEP,
            maxEP: GameMechanicsConstants.startingEP,
            baseHeroAttributes: HeroAttributes(
                hitPoints: Attribute(100),
                manaPoints: 0,
                agility: 10,
                strength: 10,
                power: 10,
                instinct: 10,
                endurance: 0
            ),
            attacks: [AttackProfile(minimumAttack: 1, maximumAttack: 5, epBlockCost: 0)],
            defensePoints: 1,
            armorValues: [:]
        )
    }

    private func makeBattle(heroHP: Int) -> Battle {
        Battle(leftTeam: [makeCombatant(currentHP: heroHP)], rightTeam: [makeCombatant(currentHP: 50)])
    }

    // MARK: - Dungeon fixtures (T18: finishBattle()'s own checkpoint save is dungeon-scoped)

    private let dungeonId = DungeonID(rawValue: UUID())
    private let roomAId = DungeonRoomID(rawValue: UUID())

    private struct FakeDungeonRepository: DungeonRepository {
        let dungeon: Dungeon
        func getAll() -> [Dungeon] { [dungeon] }
        func getById(id: DungeonID) -> Dungeon? { id == dungeon.id ? dungeon : nil }
        func randomDungeon() -> Dungeon? { dungeon }
    }

    private func makeDungeon() -> Dungeon {
        let roomA = DungeonRoom(id: roomAId, title: "Entry", kind: .combat([]), nextRoomIds: [])
        return Dungeon(
            id: dungeonId, title: "Test Dungeon", description: "",
            type: .onePath, world: .upper, backgroundImageName: "bg",
            entryRoomIds: [roomAId], rooms: [roomA]
        )
    }

    /// Starts a real dungeon run on `session` so `session.dungeonSession != nil`
    /// — the signal `finishBattle()` uses to decide its checkpoint save is its
    /// own responsibility (a hunt battle has no dungeon session and instead
    /// self-saves inside `concludeHuntBattle()`).
    private func startDungeonRun(on session: GameSession, lifecycleMutator: any DungeonLifecycleMutator) {
        withDependencies {
            $0.dungeonLifecycleMutator = lifecycleMutator
            $0.dungeonRepository = FakeDungeonRepository(dungeon: makeDungeon())
        } operation: {
            session.startDungeonSession(dungeonId: dungeonId, allyIds: [])
        }
    }

    private func makeGame() -> Game {
        let player = TestFixtures.elf()
        let members = [player] + (0..<(House.membersCount - 1)).map { _ in TestFixtures.elf() }
        let houses: [House] = (0..<Game.housesCount).map { i in
            House(name: "H\(i)", logoImageName: "logo", members: members)
        }
        let calendar = [GameDay(dayNumber: 1, dayType: .normal)]
        let gameState = GameState(currentDay: calendar[0], calendar: calendar)
        return Game(houses: houses, gameState: gameState, playerHouseIndex: 0, playerMemberIndex: 0)
    }

    private func makeSession(
        dungeonLifecycleMutator: any DungeonLifecycleMutator,
        gameRepository: SpyGameSaveStorage
    ) -> GameSession {
        withDependencies {
            $0.gameRepository = gameRepository
            $0.dungeonLifecycleMutator = dungeonLifecycleMutator
            $0.inventoryService = ElfInventoryService()
            $0.craftService = DefaultCraftService()
        } operation: {
            GameSession(game: makeGame())
        }
    }

    // MARK: - Hero downed: bank then save

    func testFinishBattle_HeroDowned_BanksRewardsThenSavesInBackground() async {
        let log = CallSequenceLog()
        let lifecycleSpy = SpyDungeonLifecycleMutator(log: log)
        let storageSpy = SpyGameSaveStorage(log: log)
        let session = makeSession(dungeonLifecycleMutator: lifecycleSpy, gameRepository: storageSpy)
        startDungeonRun(on: session, lifecycleMutator: lifecycleSpy)

        let vm = withDependencies {
            $0.gameRepository = storageSpy
            $0.dungeonLifecycleMutator = lifecycleSpy
            $0.botAI = ElfRandomBotAI()
            $0.battleLogger = ElfBattleLogger()
            $0.buffEffectsCalculator = PassthroughBuffEffectsCalculator()
            $0.equippedSlotResolver = DefaultHeroEquippedSlotResolver()
        } operation: { () -> BattleFightViewModel in
            let vm = BattleFightViewModel(battle: self.makeBattle(heroHP: 0), session: session, onBattleConcluded: nil)
            vm.battleEnded = true
            return vm
        }

        await withDependencies {
            $0.gameRepository = storageSpy
            $0.dungeonLifecycleMutator = lifecycleSpy
        } operation: {
            await vm.finishBattle()
        }
        await session.awaitInFlightSave()

        XCTAssertEqual(lifecycleSpy.bankDungeonRewardsOnDeathCallCount, 1)
        XCTAssertEqual(storageSpy.saveCallCount, 1)
        // AC-04: rewards must be banked BEFORE the checkpoint save lands.
        XCTAssertEqual(log.events, ["bank", "save"])
    }

    // MARK: - Hero survives: checkpoint save only, no banking

    func testFinishBattle_HeroSurvives_SkipsBankingButStillSaves() async {
        let log = CallSequenceLog()
        let lifecycleSpy = SpyDungeonLifecycleMutator(log: log)
        let storageSpy = SpyGameSaveStorage(log: log)
        let session = makeSession(dungeonLifecycleMutator: lifecycleSpy, gameRepository: storageSpy)
        startDungeonRun(on: session, lifecycleMutator: lifecycleSpy)

        let vm = withDependencies {
            $0.gameRepository = storageSpy
            $0.dungeonLifecycleMutator = lifecycleSpy
            $0.botAI = ElfRandomBotAI()
            $0.battleLogger = ElfBattleLogger()
            $0.buffEffectsCalculator = PassthroughBuffEffectsCalculator()
            $0.equippedSlotResolver = DefaultHeroEquippedSlotResolver()
        } operation: { () -> BattleFightViewModel in
            let vm = BattleFightViewModel(battle: self.makeBattle(heroHP: 100), session: session, onBattleConcluded: nil)
            vm.battleEnded = true
            return vm
        }

        await withDependencies {
            $0.gameRepository = storageSpy
            $0.dungeonLifecycleMutator = lifecycleSpy
        } operation: {
            await vm.finishBattle()
        }
        await session.awaitInFlightSave()

        XCTAssertEqual(lifecycleSpy.bankDungeonRewardsOnDeathCallCount, 0)
        XCTAssertEqual(storageSpy.saveCallCount, 1)
        XCTAssertEqual(log.events, ["save"])
    }

    // MARK: - Hero downed with a launcher: launcher runs BEFORE banking (T14 / review finding #1+#2)

    /// Fake reward calculator returning a fixed, known roll — mirrors
    /// `RoomBattleRewardMutatorTests.FakeDungeonRewardCalculator` — so the
    /// room's reward is deterministic instead of RNG-rolled loot.
    private struct FakeDungeonRewardCalculator: DungeonRewardCalculator {
        let rewards: [HuntRewards]
        func roomRewards(monsters: [MonsterRef]) -> [HuntRewards] { rewards }
    }

    /// Fake drop service — this test only asserts on banked XP, so item drops
    /// are irrelevant; returning none keeps the reward deterministic.
    private struct FakeDropService: DropService {
        func convertToDropItems(rewards: HuntRewards, didWin: Bool) -> [DropItem] { [] }
    }

    /// The launcher (`onBattleConcluded`) is what runs `concludeRoomBattle`,
    /// which adds the just-cleared room's reward to `pendingRewards` — so it
    /// must run BEFORE `bankDungeonRewardsOnDeath()` flushes `pendingRewards`
    /// to the player, or the fatal room's reward is banked one step too late
    /// (and lost if the app doesn't reach a later flush point).
    ///
    /// Exercised against the REAL `DungeonSession.concludeRoomBattle(...)` and
    /// the REAL `DefaultDungeonLifecycleMutator` (not spies): a reversed order
    /// would leave `session.state.player.currentExp` at 0 (the room's reward
    /// rolled after the flush already ran), so this proves the actual banked
    /// business outcome, not just a logged call sequence (T14 review finding).
    /// The squad has two members so the room battle can end in `.victory`
    /// (bots wiped, ally alive) even though the hero specifically is downed —
    /// exactly the scenario `concludeRoomBattle`'s own doc comment calls out
    /// ("a room win earns its rewards whether or not the hero survived the
    /// final blow").
    func testFinishBattle_HeroDowned_InvokesLauncherBeforeBanking() async {
        let log = CallSequenceLog()
        let lifecycleMutator = DefaultDungeonLifecycleMutator()
        let storageSpy = SpyGameSaveStorage(log: log)
        let knownReward = HuntRewards(experience: 500, materials: [])
        let session = makeSession(dungeonLifecycleMutator: lifecycleMutator, gameRepository: storageSpy)
        startDungeonRun(on: session, lifecycleMutator: lifecycleMutator)
        session.dungeonSession?.beginRun()

        let vm = withDependencies {
            $0.gameRepository = storageSpy
            $0.dungeonLifecycleMutator = lifecycleMutator
            $0.botAI = ElfRandomBotAI()
            $0.battleLogger = ElfBattleLogger()
            $0.buffEffectsCalculator = PassthroughBuffEffectsCalculator()
            $0.equippedSlotResolver = DefaultHeroEquippedSlotResolver()
        } operation: { () -> BattleFightViewModel in
            let vm = BattleFightViewModel(
                battle: Battle(
                    leftTeam: [self.makeCombatant(currentHP: 0), self.makeCombatant(currentHP: 50)],
                    rightTeam: [self.makeCombatant(currentHP: 0)]
                ),
                session: session,
                onBattleConcluded: { outcome, finalLeftTeam in
                    // Stands in for the production launcher — actually invokes
                    // the real `concludeRoomBattle`, which is what genuinely
                    // adds the fatal room's reward to `pendingRewards`.
                    log.record("launcher")
                    return session.dungeonSession?.concludeRoomBattle(outcome: outcome, finalLeftTeam: finalLeftTeam)
                }
            )
            vm.battleEnded = true
            return vm
        }

        await withDependencies {
            $0.gameRepository = storageSpy
            $0.dungeonLifecycleMutator = lifecycleMutator
            $0.dropService = FakeDropService()
            $0.dungeonRewardCalculator = FakeDungeonRewardCalculator(rewards: [knownReward])
            $0.progressionService = ElfProgressionService()
        } operation: {
            await vm.finishBattle()
        }
        await session.awaitInFlightSave()

        XCTAssertEqual(log.events, ["launcher", "save"], "launcher must run before the checkpoint save")
        XCTAssertEqual(
            session.state.player.currentExp, 500,
            "AC-04: the fatal room's reward, added to pendingRewards by the launcher's concludeRoomBattle call, "
                + "must be included in the banked total — a reversed order would leave this at 0"
        )
        XCTAssertEqual(
            session.dungeonSession?.pendingRewards, .empty,
            "the ledger must be flushed into the player, not just read"
        )
    }

    // MARK: - Hunt battle (no dungeon session): finishBattle() must not self-save (T18)

    /// A hunt battle's launcher (`GameSession.concludeHuntBattle()`) already
    /// calls `saveInBackground()` internally. Without a `dungeonSession`,
    /// `finishBattle()` must not issue its own extra, redundant save pass.
    func testFinishBattle_HeroDowned_NoDungeonSession_DoesNotSelfSave() async {
        let log = CallSequenceLog()
        let lifecycleSpy = SpyDungeonLifecycleMutator(log: log)
        let storageSpy = SpyGameSaveStorage(log: log)
        let session = makeSession(dungeonLifecycleMutator: lifecycleSpy, gameRepository: storageSpy)
        XCTAssertNil(session.dungeonSession)

        let vm = withDependencies {
            $0.gameRepository = storageSpy
            $0.dungeonLifecycleMutator = lifecycleSpy
            $0.botAI = ElfRandomBotAI()
            $0.battleLogger = ElfBattleLogger()
            $0.buffEffectsCalculator = PassthroughBuffEffectsCalculator()
            $0.equippedSlotResolver = DefaultHeroEquippedSlotResolver()
        } operation: { () -> BattleFightViewModel in
            let vm = BattleFightViewModel(battle: self.makeBattle(heroHP: 0), session: session, onBattleConcluded: nil)
            vm.battleEnded = true
            return vm
        }

        await withDependencies {
            $0.gameRepository = storageSpy
            $0.dungeonLifecycleMutator = lifecycleSpy
        } operation: {
            await vm.finishBattle()
        }
        await session.awaitInFlightSave()

        XCTAssertEqual(storageSpy.saveCallCount, 0)
    }
}
