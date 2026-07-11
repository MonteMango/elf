//
//  GameSession_RewardApplicationDelegationTests.swift
//  elf_KitTests
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import XCTest
@testable import elf_Kit

/// AC-06 real-delegation check for T7: `GameSession.concludeHuntBattle` must
/// reduce to a single delegating call into the injected
/// `RewardApplicationMutator` — not reimplement the reward-application rule
/// inline. Proven here with a spy mutator whose canned return values are
/// deliberately impossible for `GameSession` to have produced on its own
/// (arbitrary sentinel experience/reward values): if the session's observable
/// post-call state exactly mirrors the spy's output, the facade must be
/// *using* the injected value rather than computing its own.
@MainActor
final class GameSession_RewardApplicationDelegationTests: XCTestCase {

    // MARK: - Spy

    private final class SpyRewardApplicationMutator: RewardApplicationMutator, @unchecked Sendable {
        var concludeHuntBattleCallCount = 0
        var receivedPlayerCurrentExp: [Int] = []
        let sentinelResult: RewardApplicationResult

        init(sentinelResult: RewardApplicationResult) {
            self.sentinelResult = sentinelResult
        }

        func concludeHuntBattle(
            battle: Battle,
            outcome: BattleOutcome,
            playerCurrentExp: Int
        ) -> RewardApplicationResult {
            concludeHuntBattleCallCount += 1
            receivedPlayerCurrentExp.append(playerCurrentExp)
            return sentinelResult
        }
    }

    // MARK: - Fakes

    private struct NoOpStorage: GameSaveStorage {
        func save(_ game: Game, dungeonRun: DungeonRunSaveData?, slotId: String, playTime: TimeInterval) async throws {}
        func load(slotId: String) async throws -> LoadedSave { fatalError("unused") }
        func hasAnySave() -> Bool { false }
        func getPlayTime(slotId: String) async -> TimeInterval { 0 }
    }

    // MARK: - Fixtures

    private func makeGame(playerCurrentExp: Int) -> Game {
        let player = TestFixtures.elf(currentExp: playerCurrentExp)
        let members = [player] + (0..<(House.membersCount - 1)).map { _ in TestFixtures.elf() }
        let houses: [House] = (0..<Game.housesCount).map { i in
            House(name: "H\(i)", logoImageName: "logo", members: members)
        }
        let calendar = [GameDay(dayNumber: 1, dayType: .normal)]
        let gameState = GameState(currentDay: calendar[0], calendar: calendar)
        return Game(houses: houses, gameState: gameState, playerHouseIndex: 0, playerMemberIndex: 0)
    }

    /// Builds the session and invokes `concludeHuntBattle` inside the *same*
    /// `withDependencies` scope. `GameSession.concludeHuntBattle` resolves
    /// `rewardApplicationMutator` lazily (not stored at init, see its
    /// doc comment), so the override must still be in scope at call time —
    /// not just at construction.
    private func runConcludeHuntBattle(
        playerCurrentExp: Int,
        spy: SpyRewardApplicationMutator,
        outcome: BattleOutcome
    ) -> (session: GameSession, result: ManualBattleResult) {
        withDependencies {
            $0.gameRepository = NoOpStorage()
            $0.rewardApplicationMutator = spy
            // `GameSession`'s init resolves these eagerly (not lazily), so
            // every test constructing a session needs live test doubles —
            // mirrors the pattern in `GameSession_InventoryAddTests`.
            $0.inventoryService = ElfInventoryService()
            $0.craftService = DefaultCraftService()
        } operation: {
            let session = GameSession(game: makeGame(playerCurrentExp: playerCurrentExp))
            let battle = Battle(leftTeam: [], rightTeam: [])
            let result = session.concludeHuntBattle(battle: battle, outcome: outcome)
            return (session, result)
        }
    }

    // MARK: - Delegation

    func testConcludeHuntBattle_DelegatesToInjectedMutator() {
        let sentinelExperienceGained = 987_654
        let sentinelResult = RewardApplicationResult(
            manualBattleResult: ManualBattleResult(
                outcome: .victory,
                experienceGained: sentinelExperienceGained,
                drops: [],
                previousLevel: 1, previousExp: 0, previousExpToNext: 100,
                newLevel: 1, newExp: sentinelExperienceGained, newExpToNext: 100
            ),
            experienceToAdd: sentinelExperienceGained,
            huntRewardsToAdd: nil
        )
        let spy = SpyRewardApplicationMutator(sentinelResult: sentinelResult)

        let (session, result) = runConcludeHuntBattle(playerCurrentExp: 10, spy: spy, outcome: .victory)

        XCTAssertEqual(spy.concludeHuntBattleCallCount, 1)
        // Returned result is exactly the sentinel — the facade did not
        // recompute the reward itself.
        XCTAssertEqual(result.experienceGained, sentinelExperienceGained)
        // The facade wrote the mutator's reported experience into state —
        // proof it applied the *injected* value, not one it computed inline.
        XCTAssertEqual(session.state.player.currentExp, 10 + sentinelExperienceGained)
    }

    func testConcludeHuntBattle_PassesPreMutationExpToMutator() {
        let spy = SpyRewardApplicationMutator(
            sentinelResult: RewardApplicationResult(
                manualBattleResult: ManualBattleResult(
                    outcome: .defeat, experienceGained: 0, drops: [],
                    previousLevel: 1, previousExp: 5, previousExpToNext: 100,
                    newLevel: 1, newExp: 5, newExpToNext: 100
                ),
                experienceToAdd: 0,
                huntRewardsToAdd: nil
            )
        )

        _ = runConcludeHuntBattle(playerCurrentExp: 5, spy: spy, outcome: .defeat)

        XCTAssertEqual(spy.receivedPlayerCurrentExp, [5])
    }

    // MARK: - AC-04 invariant #1, facade-level (review finding #2)

    /// Facade-level regression test for AC-04 invariant #1, driven through the
    /// **real** `DefaultRewardApplicationMutator` + **real**
    /// `DefaultBattleResultCalculator` (not spies) — the mutator-level test in
    /// `RewardApplicationMutatorTests` is near-tautological now that
    /// `concludeHuntBattle` is a pure pass-through, so the ordering guarantee
    /// actually lives here, at the `GameSession` facade: the reward result
    /// must be computed against `state.player.currentExp` as it stood
    /// *before* `concludeHuntBattle` applies any mutation. A real monster with
    /// a guaranteed hunt reward (100% chance) makes this observable — if a
    /// future change reordered the read after the mutation, `previousExp`
    /// would reflect the already-bumped value instead of the true starting one.
    private final class FakeMonsterRepository: MonsterRepository, @unchecked Sendable {
        let monster: Monster
        init(monster: Monster) { self.monster = monster }
        func getAll() -> [Monster] { [monster] }
        func getById(id: MonsterID) -> Monster? { id == monster.id ? monster : nil }
        func getMonsters(world: WorldType, level: Int) -> [Monster] { [monster] }
    }

    /// Deterministic hunt/drop doubles — `ElfHuntService`/`DefaultDropService`
    /// pull `Double.random` rolls and a live `materialRepository` respectively,
    /// neither of which this test needs; only `DefaultRewardApplicationMutator`
    /// + `DefaultBattleResultCalculator` (the two types this finding names)
    /// must be real.
    private final class FixedHuntService: HuntService, @unchecked Sendable {
        let rewards: HuntRewards
        init(experience: Int) { self.rewards = HuntRewards(experience: experience, materials: []) }
        func calculateRewards(for monster: Monster) -> HuntRewards { rewards }
    }

    private final class NoDropService: DropService, @unchecked Sendable {
        func convertToDropItems(rewards: HuntRewards, didWin: Bool) -> [DropItem] { [] }
    }

    private func makeMonster() -> Monster {
        Monster(
            id: MonsterID(),
            title: "Facade Test Monster",
            imageName: "",
            expReward: [ChanceAmount(amount: 30, chance: 1.0)],
            rightAttack: AttackProfile(minimumAttack: 1, maximumAttack: 3, epBlockCost: 100),
            leftAttack: nil,
            defensePoints: 2,
            hitPoints: 40,
            manaPoints: 0,
            strength: 5, agility: 5, power: 5, instinct: 5, endurance: 5,
            partsProtection: PartsProtection(head: 0, left: 0, center: 0, right: 0, legs: 0),
            drops: MonsterDrops(weapons: [], armor: [], materials: [])
        )
    }

    private func makeMonsterCombatant(monster: Monster) -> CombatantSnapshot {
        CombatantSnapshot(
            source: .monster(monster.id),
            name: monster.title,
            imageName: monster.imageName,
            combatantType: .monster,
            currentHP: monster.hitPoints,
            currentMP: monster.manaPoints,
            currentEP: 0,
            maxEP: 0,
            baseHeroAttributes: HeroAttributes(),
            attacks: [],
            defensePoints: monster.defensePoints,
            armorValues: [:]
        )
    }

    func testConcludeHuntBattle_RealMutatorAndCalculator_ReportsPreMutationExpAsPreviousExp() {
        let monster = makeMonster()
        let startingExp = 120

        let result = withDependencies {
            $0.gameRepository = NoOpStorage()
            $0.inventoryService = ElfInventoryService()
            $0.craftService = DefaultCraftService()
            $0.monsterRepository = FakeMonsterRepository(monster: monster)
            $0.huntService = FixedHuntService(experience: 30)
            $0.dropService = NoDropService()
            $0.progressionService = ElfProgressionService()
            $0.rewardApplicationMutator = DefaultRewardApplicationMutator()
        } operation: { () -> ManualBattleResult in
            // Constructed here (inside `operation`, not the setup closure
            // above) so its own `@Dependency(\.huntService)`/`\.dropService`
            // pulls at init time actually observe the fixed doubles — a
            // `withDependencies` setup closure only takes effect for the
            // *operation*, not for eager construction performed while still
            // building that same closure's overrides.
            let calculator = DefaultBattleResultCalculator()
            return withDependencies {
                $0.battleResultCalculator = calculator
            } operation: {
                let session = GameSession(game: makeGame(playerCurrentExp: startingExp))
                let battle = Battle(leftTeam: [makeMonsterCombatant(monster: monster)], rightTeam: [makeMonsterCombatant(monster: monster)])
                return session.concludeHuntBattle(battle: battle, outcome: .victory)
            }
        }

        // Sanity: the real stack actually granted the guaranteed reward —
        // otherwise this test would trivially pass with no mutation to order.
        XCTAssertEqual(result.experienceGained, 30)
        XCTAssertEqual(result.previousExp, startingExp)
    }
}
