//
//  HeroDisplayView.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 16.11.25.
//

import Dependencies
import elf_Kit
import elf_SwiftUI
import SwiftUI

// MARK: - HeroDisplayView

struct HeroDisplayView: View {

    // MARK: - Properties

    let display: HeroDisplayState
    let roundResults: [BodyPart: PointStatus]

    @Dependency(\.pointStatusFormatter) private var pointStatusFormatter

    // MARK: - Body

    var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        VStack(spacing: 10) {
            VStack(spacing: 2) {
                hpBar
                // TODO: [buffs/P2] render MP bar between hpBar and epBar — data already in display.currentMP/maxMP (effective). Blocked on a magic mechanic that actually spends MP; rendering 0/0 today would be visual debt.
                epBar
                if !display.buffBadges.isEmpty {
                    BuffBadgeStripView(badges: display.buffBadges)
                        .padding(.top, 2)
                }
            }

            // Hero Image with overlays
            ZStack {
                CombatantBodyView(
                    imageName: display.imageName,
                    equippedItems: display.equippedItems
                )

                // Per-round result dots — battle-only, stays on the outer caller.
                resultDotsOverlay
            }

            // Attributes (effective values; buff-folded combat math is what the
            // player sees on-screen).
            elf_SwiftUI.AttributesCompactView(
                strength: display.strength.effective,
                agility: display.agility.effective,
                power: display.power.effective,
                instinct: display.instinct.effective,
                endurance: display.endurance.effective
            )
        }
    }

    // MARK: - Private Views

    private var hpBar: some View {
        // GeometryReader gives the fill an explicit width — corner radius
        // stays correct at low percentages (scaleEffect would distort it).
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: ElfSizing.BattleFight.hpBarHeight / 2)
                    .fill(ElfColors.ProgressBar.background)

                RoundedRectangle(cornerRadius: ElfSizing.BattleFight.hpBarHeight / 2)
                    .fill(ElfColors.ProgressBar.hp)
                    .frame(width: geometry.size.width * hpPercentage)

                Text("\(display.currentHP)/\(display.maxHP)")
                    .font(ElfFonts.Component.statValue)
                    .foregroundStyle(ElfColors.Text.primaryLight)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: ElfSizing.BattleFight.hpBarHeight)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Hit points")
        .accessibilityValue("\(display.currentHP) of \(display.maxHP)")
    }

    private var epBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: ElfSizing.BattleFight.epBarHeight / 2)
                    .fill(ElfColors.ProgressBar.background)

                RoundedRectangle(cornerRadius: ElfSizing.BattleFight.epBarHeight / 2)
                    .fill(ElfColors.ProgressBar.ep)
                    .frame(width: geometry.size.width * epPercentage)

                Text("\(display.currentEP)/\(display.maxEP)")
                    .font(ElfFonts.Component.statLabel)
                    .foregroundStyle(ElfColors.Text.primaryLight)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: ElfSizing.BattleFight.epBarHeight)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Endurance points")
        .accessibilityValue("\(display.currentEP) of \(display.maxEP)")
    }

    @ViewBuilder
    private var resultDotsOverlay: some View {
        GeometryReader { geometry in
            let centerX = geometry.size.width / 2
            let centerY = geometry.size.height / 2
            let offset: CGFloat = 30

            ZStack {
                // Top - Head
                if let status = roundResults[.head] {
                    resultLabel(status: status)
                        .position(x: centerX, y: centerY - offset)
                }

                // Center - Body
                if let status = roundResults[.body] {
                    resultLabel(status: status)
                        .position(x: centerX, y: centerY)
                }

                // Left - Left Hand
                if let status = roundResults[.leftHand] {
                    resultLabel(status: status)
                        .position(x: centerX - offset, y: centerY)
                }

                // Right - Right Hand
                if let status = roundResults[.rightHand] {
                    resultLabel(status: status)
                        .position(x: centerX + offset, y: centerY)
                }

                // Bottom - Legs
                if let status = roundResults[.legs] {
                    resultLabel(status: status)
                        .position(x: centerX, y: centerY + offset)
                }
            }
        }
    }

    @ViewBuilder
    private func resultLabel(status: PointStatus) -> some View {
        if let text = pointStatusFormatter.shortLabel(for: status) {
            Text(text)
                .font(Font.system(size: 12, weight: .bold))
                .foregroundStyle(statusColor(for: status))
        }
    }

    private func statusColor(for status: PointStatus) -> Color {
        switch status {
        case .dodged:
            return ElfColors.Battle.dodged
        case .hit:
            return ElfColors.Battle.hit
        case .critHit:
            return ElfColors.Battle.critHit
        case .blocked:
            return ElfColors.Battle.blocked
        case .weakBlocked:
            return ElfColors.Battle.weakBlocked
        case .nothing:
            return ElfColors.Battle.nothing
        }
    }

    // MARK: - Computed Properties

    private var hpPercentage: CGFloat {
        guard display.maxHP > 0 else { return 0 }
        return min(max(0, CGFloat(display.currentHP) / CGFloat(display.maxHP)), 1)
    }

    private var epPercentage: CGFloat {
        guard display.maxEP > 0 else { return 0 }
        return min(max(0, CGFloat(display.currentEP) / CGFloat(display.maxEP)), 1)
    }
}

// MARK: - Preview

#Preview {
    let monsterDisplay = HeroDisplayState(
        id: UUID(),
        name: "Goblin",
        level: 1,
        imageName: "monster_goblin",
        currentHP: 120,
        maxHP: 150,
        currentMP: 0,
        maxMP: 0,
        currentEP: 1400,
        maxEP: 2000,
        strength: AttributeDisplay(base: 15, effective: 15),
        agility: AttributeDisplay(base: 10, effective: 10),
        power: AttributeDisplay(base: 12, effective: 12),
        instinct: AttributeDisplay(base: 8, effective: 8),
        endurance: AttributeDisplay(base: 0, effective: 0),
        attackPointsCount: 1,
        defensePointsCount: 2,
        equippedItems: [:],
        buffBadges: [],
        isAlive: true
    )

    let elfDisplay = HeroDisplayState(
        id: UUID(),
        name: "Elara",
        level: 5,
        imageName: "elf_warrior",
        currentHP: 180,
        maxHP: 225,
        currentMP: 0,
        maxMP: 0,
        currentEP: 2000,
        maxEP: 2000,
        strength: AttributeDisplay(base: 18, effective: 18),
        agility: AttributeDisplay(base: 12, effective: 12),
        power: AttributeDisplay(base: 14, effective: 14),
        instinct: AttributeDisplay(base: 10, effective: 10),
        endurance: AttributeDisplay(base: 0, effective: 0),
        attackPointsCount: 2,
        defensePointsCount: 3,
        equippedItems: [:],
        buffBadges: [],
        isAlive: true
    )

    return HStack(spacing: 30) {
        HeroDisplayView(
            display: monsterDisplay,
            roundResults: [
                .head: .blocked(epSpent: 200),
                .body: .hit(weaponDamage: 8, strengthDamage: 5, enduranceReduction: 0, defenderArmor: 3),
                .leftHand: .nothing,
                .rightHand: .critHit(weaponDamage: 12, strengthDamage: 8, enduranceReduction: 0, defenderArmor: 0, multiplier: 2.0, epSpent: 200),
                .legs: .dodged(wasCrit: false)
            ]
        )
        .frame(width: 150)

        HeroDisplayView(
            display: elfDisplay,
            roundResults: [
                .head: .hit(weaponDamage: 4, strengthDamage: 3, enduranceReduction: 0, defenderArmor: 2),
                .body: .blocked(epSpent: 200),
                .leftHand: .dodged(wasCrit: true),
                .rightHand: .critHit(weaponDamage: 15, strengthDamage: 10, enduranceReduction: 0, defenderArmor: 0, multiplier: 1.5, epSpent: 0),
                .legs: .nothing
            ]
        )
        .frame(width: 150)
    }
    .padding()
    .background(Color.white)
}
