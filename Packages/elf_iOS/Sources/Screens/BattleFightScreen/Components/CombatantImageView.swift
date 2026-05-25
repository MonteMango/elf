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
    let cell: CombatantCellState
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
            Image(cell.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)

            // Red X overlay for defeated combatants
            if !cell.isAlive {
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
        cell: CombatantCellState(id: UUID(), imageName: "elf_player", isAlive: true),
        isActive: true
    )
}

#Preview("Inactive Combatant") {
    CombatantImageView(
        cell: CombatantCellState(id: UUID(), imageName: "elf_player", isAlive: true),
        isActive: false
    )
}

#Preview("Defeated Combatant") {
    CombatantImageView(
        cell: CombatantCellState(id: UUID(), imageName: "elf_player", isAlive: false),
        isActive: false
    )
}
