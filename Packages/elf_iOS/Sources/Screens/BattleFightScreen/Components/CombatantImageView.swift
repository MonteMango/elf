//
//  CombatantImageView.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import elf_SwiftUI
import SwiftUI

/// Displays a combatant's image with size based on active state and defeated overlay.
struct CombatantImageView: View {
    let snapshot: CombatantSnapshot
    let isActive: Bool

    private var size: CGFloat {
        isActive
            ? ElfSizing.BattleFight.teamImageActiveSize
            : ElfSizing.BattleFight.teamImageSize
    }

    var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        ZStack {
            // Combatant image
            Image(snapshot.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)

            // Red X overlay for defeated combatants
            if !snapshot.isAlive {
                Image(systemName: "xmark")
                    .font(.system(size: size * 0.6, weight: .bold))
                    .foregroundStyle(.red)
            }
        }
        .frame(width: size, height: size)
        .background(Color.gray)
    }
}

#Preview("Active Combatant") {
    CombatantImageView(
        snapshot: CombatantSnapshot(
            sourceId: UUID(),
            name: "Test",
            imageName: "elf_player",
            combatantType: .elf,
            currentHP: 100,
            maxHP: 100,
            strength: 10,
            agility: 10,
            power: 10,
            intuition: 10,
            attackPoints: 1,
            defensePoints: 2,
            minimumAttack: 5,
            maximumAttack: 10,
            armorValues: [:]
        ),
        isActive: true
    )
}

#Preview("Inactive Combatant") {
    CombatantImageView(
        snapshot: CombatantSnapshot(
            sourceId: UUID(),
            name: "Test",
            imageName: "elf_player",
            combatantType: .elf,
            currentHP: 100,
            maxHP: 100,
            strength: 10,
            agility: 10,
            power: 10,
            intuition: 10,
            attackPoints: 1,
            defensePoints: 2,
            minimumAttack: 5,
            maximumAttack: 10,
            armorValues: [:]
        ),
        isActive: false
    )
}

#Preview("Defeated Combatant") {
    CombatantImageView(
        snapshot: CombatantSnapshot(
            sourceId: UUID(),
            name: "Test",
            imageName: "elf_player",
            combatantType: .elf,
            currentHP: 0,
            maxHP: 100,
            strength: 10,
            agility: 10,
            power: 10,
            intuition: 10,
            attackPoints: 1,
            defensePoints: 2,
            minimumAttack: 5,
            maximumAttack: 10,
            armorValues: [:]
        ),
        isActive: false
    )
}
