//
//  DefaultCombatantSnapshotBuilderTests.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 09.12.25.
//

import Dependencies
import XCTest
@testable import elf_Kit

/// Tests for DefaultCombatantSnapshotBuilder
///
/// The builder creates CombatantSnapshot from:
/// - Elf configuration (name, level, attributes, EquippedItems)
/// - Monster data
final class DefaultCombatantSnapshotBuilderTests: XCTestCase {

    // MARK: - Mock Services

    /// Mock that captures the exact set of UUIDs passed in, so tests can pin
    /// down which slots contribute to armor calculation.
    final class MockArmorService: ArmorService, @unchecked Sendable {
        nonisolated(unsafe) var armorToReturn: [BodyPart: Int16] = [:]
        nonisolated(unsafe) var lastRequestedIds: [UUID] = []

        func getAllItemsArmor(for itemIds: [UUID]) -> [BodyPart: Int16] {
            lastRequestedIds = itemIds
            return armorToReturn
        }
    }

    // MARK: - Properties

    private var mockArmorService: MockArmorService!
    private var builder: DefaultCombatantSnapshotBuilder!

    // MARK: - Setup

    /// Wrap every test in `withDependencies` so the `builder`'s @Dependency property
    /// wrappers resolve to the per-test mocks.
    override func invokeTest() {
        let mockArmor = MockArmorService()
        self.mockArmorService = mockArmor

        withDependencies {
            $0.armorService = mockArmor
            // Default for tests that don't care about buff math; the two
            // buff-specific tests override with `PlusForty` locally.
            $0.buffEffectsCalculator = PassthroughBuffEffectsCalculator()
        } operation: {
            self.builder = DefaultCombatantSnapshotBuilder()
            super.invokeTest()
            self.builder = nil
            self.mockArmorService = nil
        }
    }

    // MARK: - Item Factory Helpers

    /// Local aliases to `TestFixtures` so the existing call-site spelling
    /// (`makeWeaponItem(...)`, `makeShieldItem(...)`) keeps working.
    private func makeWeaponItem(
        id: UUID = UUID(),
        title: String = "Test Weapon",
        tier: Int16 = 1,
        handUse: WeaponHandUse,
        minimumAttackPoint: Int16 = 1,
        maximumAttackPoint: Int16 = 5,
        epBlockCost: Int16 = 0,
        strength: Int16? = nil,
        agility: Int16? = nil,
        power: Int16? = nil,
        instinct: Int16? = nil,
        endurance: Int16? = nil,
        hitPoints: Int16? = nil
    ) throws -> WeaponItem {
        try TestFixtures.weaponItem(
            id: id, title: title, tier: tier,
            handUse: handUse,
            minimumAttackPoint: minimumAttackPoint,
            maximumAttackPoint: maximumAttackPoint,
            epBlockCost: epBlockCost,
            strength: strength, agility: agility, power: power,
            instinct: instinct, endurance: endurance, hitPoints: hitPoints
        )
    }

    private func makeShieldItem(
        id: UUID = UUID(),
        title: String = "Test Shield",
        tier: Int16 = 1,
        physicalDefensePoint: Int16 = 10
    ) throws -> ShieldItem {
        try TestFixtures.shieldItem(
            id: id, title: title, tier: tier,
            physicalDefensePoint: physicalDefensePoint
        )
    }

    /// Wraps a `WeaponItem` as the type-safe one-handed configuration. Throws
    /// if the underlying weapon is not actually one-handed.
    private func makeOneHandedConfig(_ item: WeaponItem) throws -> WeaponConfiguration {
        let elfWeapon = ElfWeaponItem(weaponItem: item)
        guard let oneHanded = ElfOneHandedWeaponItem(weapon: elfWeapon) else {
            throw NSError(domain: "Test", code: 0, userInfo: [NSLocalizedDescriptionKey: "Weapon is not one-handed"])
        }
        return .oneHanded(weapon: oneHanded)
    }

    // MARK: - Monster Snapshot Tests

    func testBuildSnapshot_FromMonster_SetsCorrectValues() {
        // Given
        let monster = Monster(
            id: UUID(),
            title: "Goblin",
            imageName: "monster_goblin",
            expReward: [ChanceAmount(amount: 10, chance: 1.0)],
            rightAttack: AttackProfile(minimumAttack: 5, maximumAttack: 10, epBlockCost: 300),
            defensePoints: 2,
            hitPoints: 100,
            manaPoints: 0,
            strength: 15,
            agility: 12,
            power: 8,
            instinct: 10,
            endurance: 0,
            partsProtection: PartsProtection(head: 2, left: 1, center: 3, right: 1, legs: 2),
            drops: MonsterDrops(weapons: [], armor: [], materials: [])
        )

        // When
        let snapshot = builder.buildSnapshot(from: monster, globalBuffs: [])

        // Then
        XCTAssertEqual(snapshot.name, "Goblin")
        XCTAssertEqual(snapshot.imageName, "monster_goblin")
        XCTAssertEqual(snapshot.combatantType, .monster)
        XCTAssertEqual(snapshot.level, 1)
        XCTAssertEqual(snapshot.currentHP, 100)
        XCTAssertEqual(snapshot.maxHP, 100)
        XCTAssertEqual(snapshot.baseStrength, 15)
        XCTAssertEqual(snapshot.baseAgility, 12)
        XCTAssertEqual(snapshot.basePower, 8)
        XCTAssertEqual(snapshot.baseInstinct, 10)
        XCTAssertEqual(snapshot.attackPoints, 1)
        XCTAssertEqual(snapshot.defensePoints, 2)
        XCTAssertEqual(snapshot.attacks.count, 1)
        XCTAssertEqual(snapshot.attacks[0].minimumAttack, 5)
        XCTAssertEqual(snapshot.attacks[0].maximumAttack, 10)
        XCTAssertEqual(snapshot.attacks[0].epBlockCost, 300)
    }

    func testBuildSnapshot_FromMonster_MapsArmorCorrectly() {
        // Given
        let monster = Monster(
            id: UUID(),
            title: "Test",
            imageName: "",
            expReward: [],
            rightAttack: AttackProfile(minimumAttack: 0, maximumAttack: 0, epBlockCost: 300),
            defensePoints: 2,
            hitPoints: 50,
            manaPoints: 0,
            strength: 10,
            agility: 10,
            power: 10,
            instinct: 10,
            endurance: 0,
            partsProtection: PartsProtection(head: 5, left: 3, center: 10, right: 3, legs: 7),
            drops: MonsterDrops(weapons: [], armor: [], materials: [])
        )

        // When
        let snapshot = builder.buildSnapshot(from: monster, globalBuffs: [])

        // Then
        XCTAssertEqual(snapshot.armorValues[.head], 5)
        XCTAssertEqual(snapshot.armorValues[.leftHand], 3)
        XCTAssertEqual(snapshot.armorValues[.body], 10)
        XCTAssertEqual(snapshot.armorValues[.rightHand], 3)
        XCTAssertEqual(snapshot.armorValues[.legs], 7)
    }

    // Note: monster snapshots structurally cannot carry equipment item refs —
    // `CombatantSnapshot` lost its equipment fields in PR-B. Type system enforces
    // what the previous `testBuildSnapshot_FromMonster_HasNoEquipment` asserted.

    func testBuildSnapshot_FromMonster_PreservesSourceId() {
        // Given
        let monsterId = UUID()
        let monster = Monster(
            id: monsterId,
            title: "Test",
            imageName: "",
            expReward: [],
            rightAttack: AttackProfile(minimumAttack: 0, maximumAttack: 0, epBlockCost: 300),
            defensePoints: 2,
            hitPoints: 50,
            manaPoints: 0,
            strength: 10,
            agility: 10,
            power: 10,
            instinct: 10,
            endurance: 0,
            partsProtection: PartsProtection(head: 0, left: 0, center: 0, right: 0, legs: 0),
            drops: MonsterDrops(weapons: [], armor: [], materials: [])
        )

        // When
        let snapshot = builder.buildSnapshot(from: monster, globalBuffs: [])

        // Then
        XCTAssertEqual(snapshot.sourceId, monsterId)
    }

    // MARK: - Elf Snapshot Tests

    func testBuildSnapshot_FromElfConfig_SetsBasicValues() throws {
        // Given
        let weapon = try makeWeaponItem(handUse: .oneHand)
        let equipped = EquippedItems(weapons: try makeOneHandedConfig(weapon))
        let fightStyle = HeroAttributes(
            hitPoints: 100, manaPoints: 50, agility: 10,
            strength: 15, power: 12, instinct: 8, endurance: 0
        )
        let randomLevel = HeroAttributes(
            hitPoints: 20, manaPoints: 10, agility: 2,
            strength: 3, power: 2, instinct: 1, endurance: 0
        )

        // When
        let snapshot = builder.buildSnapshot(
            name: "Test Elf",
            imageName: "elf_test",
            level: 5,
            fightStyleAttributes: fightStyle,
            randomLevelAttributes: randomLevel,
            equipped: equipped,
            globalBuffs: []
        )

        // Then
        XCTAssertEqual(snapshot.name, "Test Elf")
        XCTAssertEqual(snapshot.imageName, "elf_test")
        XCTAssertEqual(snapshot.combatantType, .elf)
        XCTAssertEqual(snapshot.level, 5)
    }

    func testBuildSnapshot_FromElfConfig_AggregatesAttributesIncludingItems() throws {
        // Given
        let weapon = try makeWeaponItem(
            handUse: .oneHand,
            strength: 5,    // item bonus that MUST land in the snapshot
            agility: 1,
            endurance: 1,
            hitPoints: 30
        )
        let equipped = EquippedItems(weapons: try makeOneHandedConfig(weapon))
        let fightStyle = HeroAttributes(
            hitPoints: 100, manaPoints: 50, agility: 10,
            strength: 15, power: 12, instinct: 8, endurance: 4
        )
        let randomLevel = HeroAttributes(
            hitPoints: 20, manaPoints: 10, agility: 5,
            strength: 5, power: 3, instinct: 2, endurance: 2
        )

        // When
        let snapshot = builder.buildSnapshot(
            name: "Test",
            imageName: "",
            level: 1,
            fightStyleAttributes: fightStyle,
            randomLevelAttributes: randomLevel,
            equipped: equipped,
            globalBuffs: []
        )

        // Then — fightStyle + randomLevel + item bonuses
        XCTAssertEqual(snapshot.currentHP, 150)  // 100 + 20 + 30
        XCTAssertEqual(snapshot.maxHP, 150)
        XCTAssertEqual(snapshot.baseStrength, 25)    // 15 + 5 + 5
        XCTAssertEqual(snapshot.baseAgility, 16)     // 10 + 5 + 1
        XCTAssertEqual(snapshot.basePower, 15)       // 12 + 3 + 0
        XCTAssertEqual(snapshot.baseInstinct, 10)   // 8 + 2 + 0
        XCTAssertEqual(snapshot.baseEndurance, 7)    // 4 + 2 + 1
    }

    // MARK: - WeaponConfiguration → snapshot

    func testBuildSnapshot_OneHanded_SingleAttackBaseDefense() throws {
        // Given
        let weapon = try makeWeaponItem(
            handUse: .oneHand,
            minimumAttackPoint: 4, maximumAttackPoint: 8,
            epBlockCost: 200
        )
        let equipped = EquippedItems(weapons: try makeOneHandedConfig(weapon))

        // When
        let snapshot = makeElfSnapshot(equipped: equipped)

        // Then
        XCTAssertEqual(snapshot.attackPoints, 1)
        XCTAssertEqual(snapshot.defensePoints, 2)
        XCTAssertEqual(snapshot.attacks.count, 1)
        XCTAssertEqual(snapshot.attacks[0].minimumAttack, 4)
        XCTAssertEqual(snapshot.attacks[0].maximumAttack, 8)
        XCTAssertEqual(snapshot.attacks[0].epBlockCost, 200)
    }

    func testBuildSnapshot_OneHandedWithShield_DefensePlusOne() throws {
        // Given
        let weapon = try makeWeaponItem(handUse: .oneHand, epBlockCost: 200)
        let elfWeapon = ElfWeaponItem(weaponItem: weapon)
        let oneHanded = try XCTUnwrap(ElfOneHandedWeaponItem(weapon: elfWeapon))
        let shieldBase = try makeShieldItem()
        let shield = ElfShieldItem(id: shieldBase.id, item: shieldBase)
        let equipped = EquippedItems(weapons: .oneHandedWithShield(weapon: oneHanded, shield: shield))

        // When
        let snapshot = makeElfSnapshot(equipped: equipped)

        // Then
        XCTAssertEqual(snapshot.attackPoints, 1)
        XCTAssertEqual(snapshot.defensePoints, 3, "Shield raises base defense from 2 to 3")
        XCTAssertEqual(snapshot.attacks.count, 1)
        XCTAssertEqual(snapshot.attacks[0].epBlockCost, 200, "Shield config must surface the weapon's EP block cost — original bug returned 0")
    }

    func testBuildSnapshot_TwoHanded_SingleAttackBaseDefense() throws {
        // Given
        let weapon = try makeWeaponItem(
            handUse: .both,
            minimumAttackPoint: 6, maximumAttackPoint: 12,
            epBlockCost: 400
        )
        let elfWeapon = ElfWeaponItem(weaponItem: weapon)
        let twoHanded = try XCTUnwrap(ElfTwoHandedWeaponItem(weapon: elfWeapon))
        let equipped = EquippedItems(weapons: .twoHanded(weapon: twoHanded))

        // When
        let snapshot = makeElfSnapshot(equipped: equipped)

        // Then
        XCTAssertEqual(snapshot.attackPoints, 1)
        XCTAssertEqual(snapshot.defensePoints, 2)
        XCTAssertEqual(snapshot.attacks.count, 1)
        XCTAssertEqual(snapshot.attacks[0].minimumAttack, 6)
        XCTAssertEqual(snapshot.attacks[0].maximumAttack, 12)
        XCTAssertEqual(snapshot.attacks[0].epBlockCost, 400)
    }

    func testBuildSnapshot_DualWield_TwoAttackPoints_PerStrikeStats() throws {
        // Given: primary and secondary have different damage and EP costs.
        let primaryItem = try makeWeaponItem(
            handUse: .oneHand,
            minimumAttackPoint: 3, maximumAttackPoint: 7,
            epBlockCost: 150
        )
        let secondaryItem = try makeWeaponItem(
            handUse: .oneHand,
            minimumAttackPoint: 1, maximumAttackPoint: 5,
            epBlockCost: 250
        )

        let primaryElf = ElfWeaponItem(weaponItem: primaryItem)
        let secondaryElf = ElfWeaponItem(weaponItem: secondaryItem)
        let primary = try XCTUnwrap(ElfOneHandedWeaponItem(weapon: primaryElf))
        let secondary = try XCTUnwrap(ElfOneHandedWeaponItem(weapon: secondaryElf))
        let equipped = EquippedItems(weapons: .dualWield(primary: primary, secondary: secondary))

        // When
        let snapshot = makeElfSnapshot(equipped: equipped)

        // Then: two strikes, each carrying its own weapon's stats.
        XCTAssertEqual(snapshot.attackPoints, 2)
        XCTAssertEqual(snapshot.defensePoints, 2)
        XCTAssertEqual(snapshot.attacks.count, 2)

        XCTAssertEqual(snapshot.attacks[0].minimumAttack, 3, "Strike 1 = right weapon damage min")
        XCTAssertEqual(snapshot.attacks[0].maximumAttack, 7, "Strike 1 = right weapon damage max")
        XCTAssertEqual(snapshot.attacks[0].epBlockCost, 150, "Strike 1 = right weapon EP cost")

        XCTAssertEqual(snapshot.attacks[1].minimumAttack, 1, "Strike 2 = left weapon damage min")
        XCTAssertEqual(snapshot.attacks[1].maximumAttack, 5, "Strike 2 = left weapon damage max")
        XCTAssertEqual(snapshot.attacks[1].epBlockCost, 250, "Strike 2 = left weapon EP cost")
    }

    // MARK: - Armor IDs set

    func testBuildSnapshot_ArmorService_DoesNotReceivePrimaryWeaponId() throws {
        // Given: oneHandedWithShield → only shield's id should reach the armor service.
        let weapon = try makeWeaponItem(handUse: .oneHand)
        let elfWeapon = ElfWeaponItem(weaponItem: weapon)
        let oneHanded = try XCTUnwrap(ElfOneHandedWeaponItem(weapon: elfWeapon))
        let shieldBase = try makeShieldItem()
        let shield = ElfShieldItem(id: shieldBase.id, item: shieldBase)
        let equipped = EquippedItems(weapons: .oneHandedWithShield(weapon: oneHanded, shield: shield))

        // When
        _ = makeElfSnapshot(equipped: equipped)

        // Then
        XCTAssertFalse(
            mockArmorService.lastRequestedIds.contains(weapon.id),
            "Primary weapon must not be sent to armor service"
        )
        XCTAssertTrue(
            mockArmorService.lastRequestedIds.contains(shield.id),
            "Shield must reach the armor service"
        )
    }

    func testBuildSnapshot_ArmorService_ReceivesDualWieldSecondaryWeaponId() throws {
        // Given: dual-wield secondary occupies the off-hand → its id should reach armor service.
        let primaryItem = try makeWeaponItem(handUse: .oneHand)
        let secondaryItem = try makeWeaponItem(handUse: .oneHand)
        let primary = try XCTUnwrap(ElfOneHandedWeaponItem(weapon: ElfWeaponItem(weaponItem: primaryItem)))
        let secondary = try XCTUnwrap(ElfOneHandedWeaponItem(weapon: ElfWeaponItem(weaponItem: secondaryItem)))
        let equipped = EquippedItems(weapons: .dualWield(primary: primary, secondary: secondary))

        // When
        _ = makeElfSnapshot(equipped: equipped)

        // Then
        XCTAssertFalse(
            mockArmorService.lastRequestedIds.contains(primaryItem.id),
            "Primary (main-hand) weapon must not be sent to armor service"
        )
        XCTAssertTrue(
            mockArmorService.lastRequestedIds.contains(secondaryItem.id),
            "Off-hand secondary weapon must reach the armor service"
        )
    }

    func testBuildSnapshot_FromElfConfig_UsesArmorFromService() throws {
        // Given
        let weapon = try makeWeaponItem(handUse: .oneHand)
        let equipped = EquippedItems(weapons: try makeOneHandedConfig(weapon))
        mockArmorService.armorToReturn = [
            .head: 5,
            .body: 10,
            .leftHand: 3,
            .rightHand: 3,
            .legs: 7
        ]

        // When
        let snapshot = makeElfSnapshot(equipped: equipped)

        // Then
        XCTAssertEqual(snapshot.armorValues[.head], 5)
        XCTAssertEqual(snapshot.armorValues[.body], 10)
        XCTAssertEqual(snapshot.armorValues[.leftHand], 3)
        XCTAssertEqual(snapshot.armorValues[.rightHand], 3)
        XCTAssertEqual(snapshot.armorValues[.legs], 7)
    }

    // MARK: - Buff-folded initial vitals

    func testBuildSnapshot_FromElfConfig_SeedsCurrentHPMPFromEffectiveCap() throws {
        // Given: a buff calculator stub that adds +40 HP / +15 MP to whatever
        // base it receives, regardless of the buff arrays. The builder should
        // hand currentHP/currentMP the buff-folded cap so the combatant enters
        // battle "full" relative to active buffs, not capped at base.
        final class PlusForty: BuffEffectsCalculator, @unchecked Sendable {
            func apply(buffs: [AppliedBuff], to base: HeroAttributes) -> HeroAttributes {
                HeroAttributes(
                    hitPoints: base.hitPoints + Attribute(40),
                    manaPoints: base.manaPoints + Attribute(15),
                    agility: base.agility,
                    strength: base.strength,
                    power: base.power,
                    instinct: base.instinct,
                    endurance: base.endurance
                )
            }
        }

        let weapon = try makeWeaponItem(handUse: .oneHand)
        let equipped = EquippedItems(weapons: try makeOneHandedConfig(weapon))
        let fightStyle = HeroAttributes(
            hitPoints: 100, manaPoints: 50, agility: 10,
            strength: 10, power: 10, instinct: 10, endurance: 0
        )

        // When
        let snapshot: CombatantSnapshot = withDependencies {
            $0.armorService = mockArmorService
            $0.buffEffectsCalculator = PlusForty()
        } operation: {
            let buffAwareBuilder = DefaultCombatantSnapshotBuilder()
            return buffAwareBuilder.buildSnapshot(
                name: "Test",
                imageName: "",
                level: 1,
                fightStyleAttributes: fightStyle,
                randomLevelAttributes: HeroAttributes(),
                equipped: equipped,
                globalBuffs: []
            )
        }

        // Then: base maxHP/maxMP unchanged, but currentHP/currentMP take the
        // effective cap. `baseHeroAttributes` itself is still the pre-buff value
        // — buff folding happens at read time via the calculator.
        XCTAssertEqual(snapshot.maxHP, 100, "maxHP projects base, not effective")
        XCTAssertEqual(snapshot.maxMP, 50, "maxMP projects base, not effective")
        XCTAssertEqual(snapshot.currentHP, 140, "currentHP seeded from effective (base 100 + buff 40)")
        XCTAssertEqual(snapshot.currentMP, 65, "currentMP seeded from effective (base 50 + buff 15)")
    }

    func testBuildSnapshot_FromMonster_SeedsCurrentHPMPFromEffectiveCap() {
        // Parity with the elf overload: when a monster is spawned with a
        // pre-applied global buff, currentHP/currentMP should reflect the
        // buff-folded cap, not raw monster base. Same `PlusForty` shape as
        // the elf test — kept local to keep the stub self-contained.
        final class PlusForty: BuffEffectsCalculator, @unchecked Sendable {
            func apply(buffs: [AppliedBuff], to base: HeroAttributes) -> HeroAttributes {
                HeroAttributes(
                    hitPoints: base.hitPoints + Attribute(40),
                    manaPoints: base.manaPoints + Attribute(15),
                    agility: base.agility,
                    strength: base.strength,
                    power: base.power,
                    instinct: base.instinct,
                    endurance: base.endurance
                )
            }
        }

        let monster = Monster(
            id: UUID(),
            title: "Boss",
            imageName: "boss",
            expReward: [],
            rightAttack: AttackProfile(minimumAttack: 5, maximumAttack: 10, epBlockCost: 300),
            defensePoints: 2,
            hitPoints: 100,
            manaPoints: 50,
            strength: 10,
            agility: 10,
            power: 10,
            instinct: 10,
            endurance: 0,
            partsProtection: PartsProtection(head: 0, left: 0, center: 0, right: 0, legs: 0),
            drops: MonsterDrops(weapons: [], armor: [], materials: [])
        )
        let preApplied = AppliedBuff(buffId: UUID(), appliedOnDay: 1)

        let snapshot: CombatantSnapshot = withDependencies {
            $0.armorService = mockArmorService
            $0.buffEffectsCalculator = PlusForty()
        } operation: {
            let buffAwareBuilder = DefaultCombatantSnapshotBuilder()
            return buffAwareBuilder.buildSnapshot(from: monster, globalBuffs: [preApplied])
        }

        XCTAssertEqual(snapshot.maxHP, 100, "maxHP projects base, not effective")
        XCTAssertEqual(snapshot.maxMP, 50, "maxMP projects base, not effective")
        XCTAssertEqual(snapshot.currentHP, 140, "currentHP seeded from effective (base 100 + buff 40)")
        XCTAssertEqual(snapshot.currentMP, 65, "currentMP seeded from effective (base 50 + buff 15)")
        XCTAssertEqual(snapshot.globalBuffs.count, 1, "Pre-applied buffs must propagate into the snapshot for combat math to read")
        XCTAssertEqual(snapshot.globalBuffs.first?.id, preApplied.id)
    }

    // MARK: - Helpers

    private func makeElfSnapshot(equipped: EquippedItems) -> CombatantSnapshot {
        let attributes = HeroAttributes(
            hitPoints: 100, manaPoints: 0, agility: 0,
            strength: 0, power: 0, instinct: 0, endurance: 0
        )
        return builder.buildSnapshot(
            name: "Test",
            imageName: "",
            level: 1,
            fightStyleAttributes: attributes,
            randomLevelAttributes: HeroAttributes(),
            equipped: equipped,
            globalBuffs: []
        )
    }
}
