//
//  DungeonTransitionView.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import elf_SwiftUI
import SwiftUI

/// Full-screen transition overlay shown while entering the dungeon (and, later,
/// while moving between rooms). Dims the whole screen and centers a spinner with
/// a title + subtitle describing the navigation. Mirrors `ActivityInProgressView`
/// but full-bleed, without the card backing.
struct DungeonTransitionView: View {
    let transition: DungeonTransition

    var body: some View {
        ZStack {
            ElfColors.Background.dark
                .ignoresSafeArea()

            VStack(spacing: ElfSpacing.section) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(ElfColors.primary)

                VStack(spacing: ElfSpacing.xs) {
                    Text(transition.title)
                        .font(ElfFonts.Component.sectionTitle)
                        .foregroundStyle(ElfColors.Text.primaryLight)

                    Text(transition.subtitle)
                        .font(ElfFonts.caption)
                        .foregroundStyle(ElfColors.Text.secondaryLight)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Entering") {
    DungeonTransitionView(transition: .enteringDungeon(name: "Crystal Caverns"))
}

#Preview("Room change") {
    DungeonTransitionView(transition: .movingBetweenRooms(from: "Room 1", to: "Room 2"))
}
