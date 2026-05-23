//
//  SquadElfCell.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import elf_SwiftUI
import SwiftUI

/// One Squad-tab cell. Composes Squad-specific header, HP/MP bars, buffs
/// strip, and attribute row around `CombatantBodyView` (extracted from
/// `BattleFightScreen/HeroDisplayView`). The shared body view renders portrait
/// + 3-column equipment overlay + jewelry; HP/EP bars and result-dots stay on
/// the battle side.
struct SquadElfCell: View {
    let member: DungeonSquadMemberDetail

    // MARK: - Body

    var body: some View {
        SquadElfStateOverlay(state: member.state) {
            VStack(alignment: .leading, spacing: ElfSpacing.xs) {
                SquadCellHeader(level: member.level, name: member.name)

                VStack(spacing: ElfSpacing.xxs) {
                    ResourceBar(
                        label: "HP",
                        current: member.currentHP,
                        max: member.maxHP,
                        color: ElfColors.ProgressBar.hp
                    )
                    ResourceBar(
                        label: "MP",
                        current: member.currentMP,
                        max: member.maxMP,
                        color: ElfColors.ProgressBar.mp
                    )
                }

                BuffsScrollView(buffs: member.activeBuffs)

                CombatantBodyView(
                    imageName: member.imageName,
                    equippedItems: member.equippedItems
                )
                .frame(maxHeight: ElfSizing.DungeonSquad.cellBodyMaxHeight)

                Divider()
                    .background(ElfColors.Interactive.border)
                    .padding(.top, ElfSpacing.xxs)

                AttributesCompactView(
                    strength: Int(member.attributes.strength.value),
                    agility: Int(member.attributes.agility.value),
                    power: Int(member.attributes.power.value),
                    instinct: Int(member.attributes.instinct.value),
                    endurance: Int(member.attributes.endurance.value)
                )
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(ElfSizing.DungeonSquad.cellPadding)
            .frame(width: ElfSizing.DungeonSquad.cellWidth, alignment: .top)
            .background(ElfColors.Background.dungeonCard)
            .clipShape(RoundedRectangle(cornerRadius: ElfSizing.buttonCornerRadius))
        }
    }
}
