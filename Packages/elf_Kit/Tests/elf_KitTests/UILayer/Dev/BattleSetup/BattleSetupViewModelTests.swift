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

    // MARK: - AC-02 — single, non-superseded selection resolves as today

    /// A selection that is never superseded still gets its validation's
    /// rejection/auto-resolution applied in full — e.g. equipping a
    /// two-handed weapon clears an already-equipped shield. Introducing
    /// cancellation for superseded selections must not skip, delay, or
    /// partially apply the outcome for one that was never superseded.
    func testSingleSelection_RejectionOutcomeIsAppliedInFull() async {
        let fakeValidator = FakeWeaponValidator()
        let vm = makeViewModel(weaponValidator: fakeValidator)
        let existingShield = UUID()
        vm.playerState.selectedItems[.shields] = existingShield
        let twoHandedWeapon = UUID()

        vm.equipItem(for: .player, itemType: .weapons, selectedItemId: twoHandedWeapon)
        await fakeValidator.waitUntilPending(1)

        // The real ElfWeaponValidator resolves a two-handed conflict by
        // writing `updatedItems[.shields] = nil`, which — for a dictionary
        // whose Value is itself Optional — *removes* the `.shields` key
        // rather than storing it as present-with-nil. Releasing with the
        // key omitted (not `.shields: nil`) reproduces that real shape.
        await fakeValidator.release(at: 0, with: [.weapons: ItemID(rawValue: twoHandedWeapon)])
        await drainMainActorQueue()

        XCTAssertEqual(vm.playerState.selectedItems[.weapons] ?? nil, twoHandedWeapon)
        XCTAssertEqual(vm.playerState.selectedItems[.shields] ?? nil, nil)
    }

    // MARK: - AC-02 — unequip (clearing a slot) is applied, not a no-op

    /// Unequipping goes through the same validated path and the real
    /// validator clears the slot by omitting its key from the returned
    /// dictionary (see above) — the merge must still apply that as a clear.
    func testUnequip_ClearsTheSlot() async {
        let fakeValidator = FakeWeaponValidator()
        let vm = makeViewModel(weaponValidator: fakeValidator)
        let equippedWeapon = UUID()
        vm.playerState.selectedItems[.weapons] = equippedWeapon

        vm.equipItem(for: .player, itemType: .weapons, selectedItemId: nil)
        await fakeValidator.waitUntilPending(1)

        await fakeValidator.release(at: 0, with: [:])
        await drainMainActorQueue()

        XCTAssertEqual(vm.playerState.selectedItems[.weapons] ?? nil, nil)
    }

    // MARK: - AC-05 — cross-hero independence

    /// Cancelling/superseding one hero's validation Task never cancels,
    /// delays, or otherwise interferes with the other hero's Task.
    func testCrossHeroSelections_DoNotInterfereWithEachOther() async {
        let fakeValidator = FakeWeaponValidator()
        let vm = makeViewModel(weaponValidator: fakeValidator)
        let playerWeaponA = UUID()
        let playerWeaponB = UUID()
        let botWeapon = UUID()

        vm.equipItem(for: .player, itemType: .weapons, selectedItemId: playerWeaponA)
        await fakeValidator.waitUntilPending(1)

        vm.equipItem(for: .bot, itemType: .weapons, selectedItemId: botWeapon)
        await fakeValidator.waitUntilPending(2)

        // A newer player selection supersedes only the player's Task.
        vm.equipItem(for: .player, itemType: .weapons, selectedItemId: playerWeaponB)
        await fakeValidator.waitUntilPending(3)

        // Release from the highest index down, since `release(at:)` removes
        // the entry and shifts every later index down by one. Player's newer
        // selection (index 2) resolves before the superseded first call
        // (index 0); bot's call (index 1) resolves in between, unaffected.
        await fakeValidator.release(at: 2, with: [.weapons: ItemID(rawValue: playerWeaponB)])
        await fakeValidator.release(at: 1, with: [.weapons: ItemID(rawValue: botWeapon)])
        await fakeValidator.release(at: 0, with: [.weapons: ItemID(rawValue: playerWeaponA)])
        await drainMainActorQueue()

        XCTAssertEqual(vm.playerState.selectedItems[.weapons] ?? nil, playerWeaponB)
        XCTAssertEqual(vm.botState.selectedItems[.weapons] ?? nil, botWeapon)
    }

    // MARK: - AC-06 — cross-slot rapid selection preserves both outcomes

    /// Selecting a shield while a weapon validation for the same hero is
    /// still in flight (or vice versa) never causes the other slot's
    /// already-made, not-yet-applied selection to silently revert.
    func testCrossSlotRapidSelection_BothOutcomesArePreserved() async {
        let fakeValidator = FakeWeaponValidator()
        let vm = makeViewModel(weaponValidator: fakeValidator)
        let weapon = UUID()
        let shield = UUID()

        vm.equipItem(for: .player, itemType: .weapons, selectedItemId: weapon)
        await fakeValidator.waitUntilPending(1)

        // A shield selection for the same hero before the weapon's validation
        // resolves — a different slot, so it must not cancel the weapon's Task.
        vm.equipItem(for: .player, itemType: .shields, selectedItemId: shield)
        await fakeValidator.waitUntilPending(2)

        // Shield's call resolves first, then the weapon's.
        await fakeValidator.release(at: 1, with: [.shields: ItemID(rawValue: shield)])
        await fakeValidator.release(at: 0, with: [.weapons: ItemID(rawValue: weapon)])

        // The weapon Task's own snapshot predates the shield's live write —
        // it re-validates once against the now-live state before merging
        // (see the cross-slot side-effect tests below); release that too.
        await fakeValidator.waitUntilPending(1)
        await fakeValidator.release(
            at: 0,
            with: [.weapons: ItemID(rawValue: weapon), .shields: ItemID(rawValue: shield)]
        )
        await drainMainActorQueue()

        XCTAssertEqual(vm.playerState.selectedItems[.weapons] ?? nil, weapon)
        XCTAssertEqual(vm.playerState.selectedItems[.shields] ?? nil, shield)
    }

    // MARK: - AC-02 / AC-06 — cross-slot side effect re-validates against live state

    /// The weapon and shield calls above never touch the same result key, so
    /// they can't catch a validator side effect that lands on the *other*
    /// slot. Here the weapon call's own snapshot still shows the old
    /// two-handed weapon at the moment it's called, and a shield selection
    /// resolves in between — the shield call's compatibility decision must
    /// be re-checked against the live (already one-handed) weapon before
    /// writing, or it would wrongly clear the weapon selection that already
    /// landed.
    func testCrossSlotSideEffect_WeaponWriteSurvivesAStaleShieldValidation() async {
        let fakeValidator = FakeWeaponValidator()
        let vm = makeViewModel(weaponValidator: fakeValidator)
        let twoHandedWeapon = UUID()
        let oneHandedWeapon = UUID()
        let shield = UUID()
        vm.playerState.selectedItems[.weapons] = twoHandedWeapon

        vm.equipItem(for: .player, itemType: .weapons, selectedItemId: oneHandedWeapon)
        await fakeValidator.waitUntilPending(1)

        vm.equipItem(for: .player, itemType: .shields, selectedItemId: shield)
        await fakeValidator.waitUntilPending(2)

        // Weapon's call resolves first: on its own it's simply compatible,
        // nothing to clear.
        await fakeValidator.release(at: 0, with: [.weapons: ItemID(rawValue: oneHandedWeapon)])
        await drainMainActorQueue()

        // Shield's call resolves against its *stale* snapshot (weapon still
        // looked two-handed when it was called) — the real validator would
        // have cleared `.weapons` for that stale picture. Releasing it
        // triggers a live re-check, which issues a second validator call.
        await fakeValidator.release(at: 0, with: [.shields: ItemID(rawValue: shield)])
        await fakeValidator.waitUntilPending(1)
        await fakeValidator.release(
            at: 0,
            with: [.weapons: ItemID(rawValue: oneHandedWeapon), .shields: ItemID(rawValue: shield)]
        )
        await drainMainActorQueue()

        XCTAssertEqual(vm.playerState.selectedItems[.weapons] ?? nil, oneHandedWeapon)
        XCTAssertEqual(vm.playerState.selectedItems[.shields] ?? nil, shield)
    }

    /// Mirror scenario with the roles reversed: the shield slot is empty
    /// when the weapon call is made (so `.shields` never appears in its
    /// snapshot at all), a shield lands live while the weapon validation is
    /// in flight, and the weapon turns out to be two-handed. Without a live
    /// re-check, `.shields` would never even be visited by the weapon call's
    /// merge (its stale snapshot never had that key), leaving a two-handed
    /// weapon and a shield equipped at the same time.
    func testCrossSlotSideEffect_TwoHandedWeaponClearsALiveConcurrentShield() async {
        let fakeValidator = FakeWeaponValidator()
        let vm = makeViewModel(weaponValidator: fakeValidator)
        let oneHandedWeapon = UUID()
        let twoHandedWeapon = UUID()
        let shield = UUID()
        vm.playerState.selectedItems[.weapons] = oneHandedWeapon

        vm.equipItem(for: .player, itemType: .weapons, selectedItemId: twoHandedWeapon)
        await fakeValidator.waitUntilPending(1)

        vm.equipItem(for: .player, itemType: .shields, selectedItemId: shield)
        await fakeValidator.waitUntilPending(2)

        // Shield's call resolves first: its own snapshot still sees the
        // one-handed weapon, so it's genuinely compatible and applies clean.
        await fakeValidator.release(
            at: 1,
            with: [.weapons: ItemID(rawValue: oneHandedWeapon), .shields: ItemID(rawValue: shield)]
        )
        await drainMainActorQueue()

        // Weapon's call resolves against its own stale snapshot (no shield
        // equipped yet when it was called) — the real validator's response
        // never mentions `.shields`. Releasing it triggers a live re-check
        // that must notice the shield which appeared underneath it.
        await fakeValidator.release(at: 0, with: [.weapons: ItemID(rawValue: twoHandedWeapon)])
        await fakeValidator.waitUntilPending(1)
        await fakeValidator.release(at: 0, with: [.weapons: ItemID(rawValue: twoHandedWeapon)])
        await drainMainActorQueue()

        XCTAssertEqual(vm.playerState.selectedItems[.weapons] ?? nil, twoHandedWeapon)
        XCTAssertEqual(vm.playerState.selectedItems[.shields] ?? nil, nil)
    }
}
