//
//  BattleSetupViewModelTests.swift
//  elf_KitTests
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import XCTest
@testable import elf_Kit

/// Regression suite for `nextArch/possiblePlans.md` finding #1 (structured
/// task cancellation): `BattleSetupViewModel.updateSelectedItems` used to run
/// an unmanaged, uncancelled `Task { }` per weapon/shield selection, so a
/// rapid re-selection raced the previous validation and whichever `await`
/// resolved last silently won — regardless of which selection was actually
/// made last. `FakeWeaponValidator` lets each test release the two races'
/// underlying calls in a chosen order, deterministically, to prove the fix.
@MainActor
final class BattleSetupViewModelTests: XCTestCase {

    // MARK: - No-op stubs (satisfy `@Dependency` resolution; unused by the paths under test)

    private struct StubAttributeService: AttributeService {
        func getAllFightStyleAttributes(for fightStyle: FightStyle, at level: Int16) -> HeroAttributes { HeroAttributes() }
        func getRandomLevelAttributes() -> HeroAttributes { HeroAttributes() }
        func getAllRandomLevelAttributes(for level: Int16) -> HeroAttributes { HeroAttributes() }
        func getAllItemsAttributes(for itemIds: [ItemID]) -> HeroAttributes { HeroAttributes() }
    }

    private struct StubArmorService: ArmorService {
        func getAllItemsArmor(for itemIds: [ItemID]) -> [BodyPart: Int16] { [:] }
    }

    private struct StubDamageService: DamageService {
        func getRandomStrengthDamage(_ strengthAttribute: Int16, using generator: WithRandomNumberGenerator) -> Int16 { 0 }
        func getRandomDamageReduction(stat: Int16, coefficient: Double, using generator: WithRandomNumberGenerator) -> Int16 { 0 }
        func getWeaponDamage(weaponId: ItemID?) -> (minDmg: Int16, maxDmg: Int16)? { nil }
        func calculateTotalDamage(from pointStatus: [BodyPart: PointStatus]) -> Int { 0 }
    }

    private struct StubSnapshotBuilder: CombatantSnapshotBuilder {
        func buildSnapshot(elf: ElfInfo, level: Int, globalBuffs: [AppliedBuff]) -> CombatantSnapshot {
            fatalError("not exercised by this suite")
        }

        func buildSnapshot(
            name: String,
            imageName: String,
            level: Int,
            fightStyleAttributes: HeroAttributes,
            randomLevelAttributes: HeroAttributes,
            equipped: EquippedItems,
            globalBuffs: [AppliedBuff]
        ) -> CombatantSnapshot {
            fatalError("not exercised by this suite")
        }

        func buildSnapshot(from monster: Monster, globalBuffs: [AppliedBuff]) -> CombatantSnapshot {
            fatalError("not exercised by this suite")
        }
    }

    // MARK: - Fixtures

    private func makeViewModel(weaponValidator: FakeWeaponValidator) -> BattleSetupViewModel {
        withDependencies {
            $0.weaponValidator = weaponValidator
            $0.itemsRepository = FakeItemsRepository()
            $0.monsterRepository = FakeMonsterRepository()
            $0.attributeService = StubAttributeService()
            $0.armorService = StubArmorService()
            $0.damageService = StubDamageService()
            $0.snapshotBuilder = StubSnapshotBuilder()
        } operation: {
            BattleSetupViewModel()
        }
    }

    /// Yields repeatedly to let every already-scheduled `@MainActor` job (a
    /// resumed validation `Task`'s remainder, which contains no further
    /// `await` after the validator call) run to completion. Not wall-clock
    /// timing — pure cooperative scheduling — so it's deterministic
    /// regardless of how many actor hops a resumption needs.
    private func drainMainActorQueue() async {
        for _ in 0..<20 {
            await Task.yield()
        }
    }

    // MARK: - AC-01 / AC-03 / AC-04 — same-slot rapid re-selection

    /// The first selection's validation Task is cancelled and, even though its
    /// underlying async call still completes afterward (a non-cooperating
    /// `await`), its stale result is denied write access — only the second,
    /// most-recent selection's outcome is ever applied.
    func testRapidSameSlotReselection_OnlyFinalSelectionIsApplied() async {
        let fakeValidator = FakeWeaponValidator()
        let vm = makeViewModel(weaponValidator: fakeValidator)
        let weaponA = UUID()
        let weaponB = UUID()

        vm.equipItem(for: .player, itemType: .weapons, selectedItemId: weaponA)
        await fakeValidator.waitUntilPending(1)

        vm.equipItem(for: .player, itemType: .weapons, selectedItemId: weaponB)
        await fakeValidator.waitUntilPending(2)

        // The second (most recent) selection's validation resolves first;
        // the first selection's stale call resolves afterward.
        await fakeValidator.release(at: 1, with: [.weapons: ItemID(rawValue: weaponB)])
        await fakeValidator.release(at: 0, with: [.weapons: ItemID(rawValue: weaponA)])
        await drainMainActorQueue()

        XCTAssertEqual(vm.playerState.selectedItems[.weapons] ?? nil, weaponB)
    }
}
