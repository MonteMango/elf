//
//  ConsoleDebugBattleLogger.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 19.11.25.
//

import Foundation

/// Console implementation of DebugBattleLogger with detailed formatted output
///
/// Outputs all battle calculations to console with:
/// - Emoji icons for visual separation
/// - Indentation for hierarchy
/// - Section dividers
/// - Color-coded important events
///
/// **For debug builds only** - use NoOpDebugBattleLogger in production
public final class ConsoleDebugBattleLogger: DebugBattleLogger {

    private let categories: Set<DebugBattleLogCategory>

    /// Initialize logger with specific categories to log
    /// - Parameter categories: Set of categories to enable logging for
    public init(categories: Set<DebugBattleLogCategory>) {
        self.categories = categories
    }

    public func logRoundStart(
        roundNumber: Int,
        playerSnapshot: CombatantSnapshot,
        botSnapshot: CombatantSnapshot,
        playerAttack: [BodyPart],
        playerDefense: [BodyPart],
        botAttack: [BodyPart],
        botDefense: [BodyPart]
    ) {
        guard categories.contains(.roundStart) else { return }

        print("\n========================================")
        print("🎮 ROUND \(roundNumber) START")
        print("========================================")

        // Player stats
        print("\n👤 PLAYER (\(playerSnapshot.name)):")
        logCombatantStats(playerSnapshot)
        print("  ⚔️ Attack: \(formatBodyParts(playerAttack))")
        print("  🛡️ Defense: \(formatBodyParts(playerDefense))")

        // Bot stats
        let botIcon = botSnapshot.combatantType == .monster ? "👾" : "🤖"
        print("\n\(botIcon) BOT (\(botSnapshot.name)):")
        logCombatantStats(botSnapshot)
        print("  ⚔️ Attack: \(formatBodyParts(botAttack))")
        print("  🛡️ Defense: \(formatBodyParts(botDefense))")
        print("")
    }

    public func logStrengthDamage(
        hero: String,
        strength: Int16,
        distribution: [Int16],
        weights: [Int],
        selectedValue: Int16
    ) {
        guard categories.contains(.strengthDamage) else { return }

        print("  💪 \(hero) Strength Damage:")
        print("    Total Strength: \(strength)")
        print("    Distribution: \(distribution)")
        print("    Weights: \(weights)")
        print("    Total Weight: \(weights.reduce(0, +))")
        print("    → Selected: \(selectedValue)")
    }

    public func logWeaponDamage(
        hero: String,
        hand: String,
        weaponName: String,
        minDamage: Int16,
        maxDamage: Int16,
        selectedValue: Int16
    ) {
        guard categories.contains(.weaponDamage) else { return }

        print("  ⚔️ \(hero) \(hand.capitalized) Hand Weapon (\(weaponName)):")
        print("    Range: [\(minDamage), \(maxDamage)]")
        print("    → Selected: \(selectedValue)")
    }

    public func logDodgeCalculation(
        defender: String,
        result: DodgeCalculationResult,
        agility: Int16,
        instinct: Int16
    ) {
        guard categories.contains(.dodgeCalculation) else { return }

        print("  🎯 \(defender) DODGE CHECK:")
        print("    Agility: \(agility), Instinct: \(instinct)")

        let dist = result.distribution
        print("    Distribution (triangular):")
        print("      Min: \(dist.minimumChance)%, Max: \(dist.maximumChance)%")

        if dist.hasRange {
            print("      Range: \(dist.rangeValues)")
            print("      Weights: \(dist.rangeWeights)")
        } else {
            print("      No range")
        }

        print("    Stage 1 (Select Chance from triangular distribution):")
        print("      → Selected: \(result.selectedChance)%")

        print("    Stage 2 (Success Check):")
        if let stage2Roll = result.stage2Roll {
            let comparison = stage2Roll <= result.selectedChance ? "≤" : ">"
            print("      Roll: \(stage2Roll) \(comparison) \(result.selectedChance)")
            print("      → \(result.success ? "✅ DODGE SUCCESS" : "❌ DODGE FAILED")")
        } else {
            if result.selectedChance <= 0 {
                print("      → ❌ AUTO-FAIL (chance <= 0)")
            } else {
                print("      → ✅ AUTO-SUCCESS (100+% chance)")
            }
        }
    }

    public func logCritCalculation(
        attacker: String,
        result: CritCalculationResult,
        power: Int16,
        instinct: Int16
    ) {
        guard categories.contains(.critCalculation) else { return }

        print("  💥 \(attacker) CRIT CALCULATION:")
        print("    Power: \(power), Defender Instinct: \(instinct)")

        let dist = result.distribution
        print("    Distribution (triangular):")
        print("      Min: \(dist.minimumChance)%, Max: \(dist.maximumChance)%")

        if dist.hasRange {
            print("      Range: \(dist.rangeValues)")
            print("      Weights: \(dist.rangeWeights)")
        } else {
            print("      No range")
        }

        print("    Stage 1 (Select Chance from triangular distribution):")
        print("      → Selected: \(result.selectedChance)%")

        print("    Stage 2 (Success Check):")
        if let stage2Roll = result.stage2Roll {
            let comparison = stage2Roll <= result.selectedChance ? "≤" : ">"
            print("      Roll: \(stage2Roll) \(comparison) \(result.selectedChance)")
            print("      → \(result.success ? "✅ CRIT SUCCESS" : "❌ CRIT FAILED")")
        } else {
            if result.selectedChance <= 0 {
                print("      → ❌ AUTO-FAIL (chance <= 0)")
            } else {
                print("      → ✅ AUTO-SUCCESS (100+% chance)")
            }
        }

        if result.success {
            print("    Stage 3 (Multiplier Selection):")
            let multDist = result.multiplierDistribution
            print("      Available: \(multDist.values) with weights \(multDist.weights)")
            if let multRoll = result.multiplierRoll {
                print("      Roll: \(multRoll)/\(multDist.totalWeight)")
            }
            print("      → Selected: x\(result.selectedMultiplier)")
        } else {
            print("    Stage 3: Skipped (crit failed, multiplier = 1.0)")
        }
    }

    public func logBodyPartCalculation(
        attacker: String,
        defender: String,
        bodyPart: BodyPart,
        isAttacked: Bool,
        isDefended: Bool,
        baseDamage: Int?,
        armor: Int?,
        finalDamage: Int?,
        finalStatus: PointStatus
    ) {
        guard categories.contains(.bodyPartCalculation) else { return }

        print("\n🎲 CALCULATING: \(bodyPartName(bodyPart))")
        print("  Attacker: \(attacker), Defender: \(defender)")
        print("  Status: \(formatAttackDefenseStatus(isAttacked: isAttacked, isDefended: isDefended))")

        if let baseDamage = baseDamage {
            print("  Base Damage: \(baseDamage)")
        }
        if let armor = armor {
            print("  Armor: \(armor)")
        }
        if let finalDamage = finalDamage {
            print("  Final Damage: \(finalDamage)")
        }

        print("  → Result: \(formatPointStatus(finalStatus))")
    }

    public func logRoundEnd(
        roundNumber: Int,
        playerOldHP: Int,
        playerNewHP: Int,
        botOldHP: Int,
        botNewHP: Int,
        playerResults: [BodyPart: PointStatus],
        botResults: [BodyPart: PointStatus]
    ) {
        guard categories.contains(.roundEnd) else { return }

        print("\n========================================")
        print("📊 ROUND \(roundNumber) RESULTS")
        print("========================================")

        let playerDamage = playerOldHP - playerNewHP
        let botDamage = botOldHP - botNewHP

        print("\n👤 PLAYER:")
        print("  HP: \(playerOldHP) → \(playerNewHP) (took \(playerDamage) damage)")
        print("  Results:")
        for bodyPart in [BodyPart.head, .body, .leftHand, .rightHand, .legs] {
            if let status = playerResults[bodyPart] {
                print("    \(bodyPartName(bodyPart)): \(formatPointStatus(status))")
            }
        }

        print("\n🤖 BOT:")
        print("  HP: \(botOldHP) → \(botNewHP) (took \(botDamage) damage)")
        print("  Results:")
        for bodyPart in [BodyPart.head, .body, .leftHand, .rightHand, .legs] {
            if let status = botResults[bodyPart] {
                print("    \(bodyPartName(bodyPart)): \(formatPointStatus(status))")
            }
        }

        print("\n========================================\n")
    }

    // MARK: - Private Helpers

    private func logCombatantStats(_ snapshot: CombatantSnapshot) {
        print("  💪 Strength: \(snapshot.strength)")
        print("  ⚡ Agility: \(snapshot.agility)")
        print("  🔥 Power: \(snapshot.power)")
        print("  🎯 Intuition: \(snapshot.intuition)")
        print("  ❤️ HP: \(snapshot.currentHP)/\(snapshot.maxHP)")

        print("  🛡️ Armor:", terminator: "")
        for bodyPart in [BodyPart.head, .body, .leftHand, .rightHand, .legs] {
            let armor = snapshot.armorValues[bodyPart] ?? 0
            print(" \(bodyPartName(bodyPart))=\(armor)", terminator: "")
        }
        print("")

        if let leftWeapon = snapshot.leftWeaponItem {
            print("  ⚔️ Left: \(leftWeapon.item.title)")
        }
        if let rightWeapon = snapshot.rightWeaponItem {
            print("  ⚔️ Right: \(rightWeapon.item.title)")
        }

        print("  📊 Attack: \(snapshot.minimumAttack)-\(snapshot.maximumAttack)")
        print("  🎯 Attack Points: \(snapshot.attackPoints), Defense Points: \(snapshot.defensePoints)")
    }

    private func formatBodyParts(_ bodyParts: [BodyPart]) -> String {
        if bodyParts.isEmpty {
            return "[]"
        }
        return "[" + bodyParts.map { bodyPartName($0) }.joined(separator: ", ") + "]"
    }

    private func bodyPartName(_ bodyPart: BodyPart) -> String {
        switch bodyPart {
        case .head: return "Head"
        case .body: return "Body"
        case .leftHand: return "L.Hand"
        case .rightHand: return "R.Hand"
        case .legs: return "Legs"
        }
    }

    private func formatAttackDefenseStatus(isAttacked: Bool, isDefended: Bool) -> String {
        if isAttacked && isDefended {
            return "⚔️🛡️ Attack + Defense"
        } else if isAttacked {
            return "⚔️ Attack only"
        } else if isDefended {
            return "🛡️ Defense only"
        } else {
            return "➖ Nothing"
        }
    }

    private func formatPointStatus(_ status: PointStatus) -> String {
        switch status {
        case .blocked:
            return "🛡️ BLOCKED"
        case .hit(let weaponDamage, let strengthDamage, let defenderArmor):
            let totalDamage = max(0, weaponDamage + strengthDamage - defenderArmor)
            return "💥 HIT (\(totalDamage) damage: weapon=\(weaponDamage) str=\(strengthDamage) armor=\(defenderArmor))"
        case .critHit(let weaponDamage, let strengthDamage, let defenderArmor, let multiplier):
            let baseDamage = weaponDamage + strengthDamage - defenderArmor
            let totalDamage = max(0, Int(Double(baseDamage) * multiplier))
            return "💥💥 CRIT HIT (\(totalDamage) damage: weapon=\(weaponDamage) str=\(strengthDamage) armor=\(defenderArmor) x\(multiplier))"
        case .dodged:
            return "💨 DODGED"
        case .nothing:
            return "➖ Nothing"
        }
    }
}

// MARK: - Sendable Conformance
extension ConsoleDebugBattleLogger: @unchecked Sendable {}
