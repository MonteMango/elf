//
//  BattleFightViewModel_VitalsRescaleDelegationTests.swift
//  elf_KitTests
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import XCTest
@testable import elf_Kit

/// AC-06 real-delegation check for T21 (architecture-hardening review finding
/// #1): `BattleFightViewModel.applyBattleBuff`'s vitals-rescale must reduce to
/// a single delegating call into the injected `VitalsRescaleMutator` — not
/// reimplement the proportional-rescale rule inline. Proven with a spy mutator
/// whose canned HP/MP values are deliberately impossible for the ViewModel to
/// have produced on its own: if the ViewModel's observable post-call state
/// exactly mirrors the spy's output, it must be *using* the injected value.
@MainActor
final class BattleFightViewModel_VitalsRescaleDelegationTests: XCTestCase {

    // MARK: - Spy

    private final class SpyVitalsRescaleMutator: VitalsRescaleMutator, @unchecked Sendable {
        var callCount = 0
        let sentinelHP: Int
        let sentinelMP: Int

        init(sentinelHP: Int, sentinelMP: Int) {
            self.sentinelHP = sentinelHP
            self.sentinelMP = sentinelMP
        }

        func rescaleVitals(combatant: inout CombatantSnapshot, before: HeroAttributes, after: HeroAttributes) {
            callCount += 1
            combatant.currentHP = sentinelHP
            combatant.currentMP = sentinelMP
        }
    }

    // MARK: - Fixtures

    private func makeCombatant(id: CombatantID = CombatantID(), currentHP: Int = 100) -> CombatantSnapshot {
        CombatantSnapshot(
            id: id,
            source: .synthetic,
            name: "C",
            imageName: "img",
            combatantType: .elf,
            level: 1,
            currentHP: currentHP,
            currentMP: 10,
            currentEP: GameMechanicsConstants.startingEP,
            maxEP: GameMechanicsConstants.startingEP,
            baseHeroAttributes: HeroAttributes(
                hitPoints: Attribute(100),
                manaPoints: 20,
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

    private func makeBattle(hero: CombatantSnapshot) -> Battle {
        Battle(leftTeam: [hero], rightTeam: [makeCombatant()])
    }

    // MARK: - applyBattleBuff → VitalsRescaleMutator

    func testApplyBattleBuff_DelegatesToInjectedVitalsRescaleMutator() {
        let hero = makeCombatant(currentHP: 50)
        let sentinelHP = 12345
        let sentinelMP = 6789
        let spy = SpyVitalsRescaleMutator(sentinelHP: sentinelHP, sentinelMP: sentinelMP)

        let vm = withDependencies {
            $0.vitalsRescaleMutator = spy
            $0.botAI = ElfRandomBotAI()
            $0.battleLogger = ElfBattleLogger()
            $0.buffEffectsCalculator = PassthroughBuffEffectsCalculator()
            $0.equippedSlotResolver = DefaultHeroEquippedSlotResolver()
            $0.equipmentQueryService = ElfEquipmentQueryService()
            $0.duelPairingService = RandomDuelPairingService()
        } operation: { () -> BattleFightViewModel in
            let vm = BattleFightViewModel(battle: makeBattle(hero: hero))
            vm.applyBattleBuff(buffId: BuffID(), toCombatantWithId: hero.id.rawValue)
            return vm
        }

        XCTAssertEqual(spy.callCount, 1)
        // The VM's observable team state exactly mirrors the spy's sentinel
        // output — proof it applied the *injected* rescale, not one it
        // computed itself (the real formula could never produce these values
        // from a 50/100 HP, 10/20 MP starting combatant).
        XCTAssertEqual(vm.leftTeam.first?.currentHP, sentinelHP)
        XCTAssertEqual(vm.leftTeam.first?.currentMP, sentinelMP)
    }
}
