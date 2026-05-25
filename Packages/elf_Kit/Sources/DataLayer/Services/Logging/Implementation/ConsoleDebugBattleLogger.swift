//
//  ConsoleDebugBattleLogger.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 19.11.25.
//

import Dependencies
import Foundation

/// Console implementation of DebugBattleLogger with detailed formatted output
///
/// Outputs all battle calculations to console with:
/// - Emoji icons for visual separation
/// - Indentation for hierarchy
/// - Section dividers
/// - Color-coded important events
///
/// Pass an empty `categories` set to disable all output.
public final class ConsoleDebugBattleLogger: DebugBattleLogger {

    private let categories: Set<DebugBattleLogCategory>
    private let buffEffectsCalculator: any BuffEffectsCalculator

    /// Initialize logger with specific categories to log
    /// - Parameter categories: Set of categories to enable logging for
    public init(categories: Set<DebugBattleLogCategory>) {
        @Dependency(\.buffEffectsCalculator) var buffEffectsCalculator
        self.categories = categories
        self.buffEffectsCalculator = buffEffectsCalculator
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

    public func logRoundState(
        roundNumber: Int,
        leftTeam: [CombatantSnapshot],
        rightTeam: [CombatantSnapshot],
        playerCombatantId: UUID?,
        battleRound: BattleRound?
    ) {
        guard categories.contains(.roundState) else { return }

        let allies = leftTeam
            .map { snapshot in
                let heroMark = snapshot.id == playerCombatantId ? " ← HERO" : ""
                let effMax = buffEffectsCalculator.effectiveAttributes(of: snapshot).hitPoints.intValue
                return "  - \(snapshot.name) [id=\(snapshot.id.uuidString.prefix(8))] HP \(snapshot.currentHP)/\(effMax)\(heroMark)"
            }
            .joined(separator: "\n")
        let enemies = rightTeam
            .map { snapshot in
                let effMax = buffEffectsCalculator.effectiveAttributes(of: snapshot).hitPoints.intValue
                return "  - \(snapshot.name) [id=\(snapshot.id.uuidString.prefix(8))] HP \(snapshot.currentHP)/\(effMax)"
            }
            .joined(separator: "\n")

        let pairs: String
        if let round = battleRound {
            pairs = round.duelPairs.enumerated().map { idx, pair in
                let leftName = leftTeam.first(where: { $0.id == pair.leftCombatantId })?.name ?? "?"
                let rightName = rightTeam.first(where: { $0.id == pair.rightCombatantId })?.name ?? "?"
                let heroMark = (pair.leftCombatantId == playerCombatantId) ? " ★" : ""
                return "  [\(idx)] \(leftName) vs \(rightName)\(heroMark)"
            }.joined(separator: "\n")
        } else {
            pairs = "  (none)"
        }
        let waitingLeft = (battleRound?.waitingLeftIds ?? [])
            .compactMap { id in leftTeam.first(where: { $0.id == id })?.name }
            .joined(separator: ", ")
        let waitingRight = (battleRound?.waitingRightIds ?? [])
            .compactMap { id in rightTeam.first(where: { $0.id == id })?.name }
            .joined(separator: ", ")

        let heroPair = battleRound?.duelPairs.first(where: { $0.leftCombatantId == playerCombatantId })
        let heroAlive = playerCombatantId.flatMap { id in leftTeam.first(where: { $0.id == id })?.isAlive } ?? false
        let heroWaiting = heroAlive && battleRound != nil && heroPair == nil

        print("""
        ==================== Round \(roundNumber) ====================
        ALLIES (\(leftTeam.filter { $0.isAlive }.count) alive / \(leftTeam.count) total):
        \(allies)
        ENEMIES (\(rightTeam.filter { $0.isAlive }.count) alive / \(rightTeam.count) total):
        \(enemies)
        PAIRS:
        \(pairs)
        WAITING left: [\(waitingLeft)]
        WAITING right: [\(waitingRight)]
        heroDuelPair=\(heroPair == nil ? "nil" : "set")  isHeroAlive=\(heroAlive)  isHeroWaiting=\(heroWaiting)
        =====================================================
        """)
    }

    // MARK: - Private Helpers

    private func logCombatantStats(_ snapshot: CombatantSnapshot) {
        let effective = buffEffectsCalculator.effectiveAttributes(of: snapshot)
        print(formatStat(emoji: "💪", name: "Strength", base: snapshot.baseStrength, effective: Int(effective.strength.value)))
        print(formatStat(emoji: "⚡", name: "Agility", base: snapshot.baseAgility, effective: Int(effective.agility.value)))
        print(formatStat(emoji: "🔥", name: "Power", base: snapshot.basePower, effective: Int(effective.power.value)))
        print(formatStat(emoji: "🎯", name: "Instinct", base: snapshot.baseInstinct, effective: Int(effective.instinct.value)))
        print("  ❤️ HP: \(snapshot.currentHP)/\(effective.hitPoints.intValue)")
        print("  🔮 MP: \(snapshot.currentMP)/\(effective.manaPoints.intValue)")

        print("  🛡️ Armor:", terminator: "")
        for bodyPart in [BodyPart.head, .body, .leftHand, .rightHand, .legs] {
            let armor = snapshot.armorValues[bodyPart] ?? 0
            print(" \(bodyPartName(bodyPart))=\(armor)", terminator: "")
        }
        print("")

        for (idx, profile) in snapshot.attacks.enumerated() {
            print("  📊 Strike \(idx + 1): \(profile.minimumAttack)-\(profile.maximumAttack) dmg, \(profile.epBlockCost) EP block cost")
        }
        print("  🎯 Attack Points: \(snapshot.attackPoints), Defense Points: \(snapshot.defensePoints)")
    }

    /// Renders a combat-attribute line. When buffs make `effective` differ from
    /// `base`, the base value is shown in parentheses so the dev can read off
    /// the buff delta directly; without buffs the line collapses to a single
    /// number to keep the log clean.
    private func formatStat(emoji: String, name: String, base: Int, effective: Int) -> String {
        base == effective
            ? "  \(emoji) \(name): \(effective)"
            : "  \(emoji) \(name): \(effective) (base \(base))"
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
        case .blocked(_, let epSpent):
            return "🛡️ BLOCKED (-\(epSpent) EP)"
        case .hit(let weaponDamage, let strengthDamage, let defenderArmor):
            let totalDamage = max(0, weaponDamage + strengthDamage - defenderArmor)
            return "💥 HIT (\(totalDamage) damage: weapon=\(weaponDamage) str=\(strengthDamage) armor=\(defenderArmor))"
        case .critHit(let weaponDamage, let strengthDamage, let defenderArmor, let multiplier, let epSpent):
            let baseDamage = weaponDamage + strengthDamage - defenderArmor
            let totalDamage = max(0, Int(Double(baseDamage) * multiplier))
            let epSuffix = epSpent > 0 ? " -\(epSpent) EP" : ""
            return "💥💥 CRIT HIT (\(totalDamage) damage: weapon=\(weaponDamage) str=\(strengthDamage) armor=\(defenderArmor) x\(multiplier)\(epSuffix))"
        case .dodged:
            return "💨 DODGED"
        case .nothing:
            return "➖ Nothing"
        }
    }
}
