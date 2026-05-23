//
//  SquadCellHeader.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_SwiftUI
import SwiftUI

/// LVL + Name header for a Squad-tab cell. Distinct from `PlayerInfoSection`
/// (which also renders an EXP bar) — squad cells deliberately omit EXP
/// because the dungeon brief is about combat readiness, not progression.
struct SquadCellHeader: View {
    let level: Int
    let name: String

    var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        HStack(spacing: ElfSpacing.component) {
            Text("LVL \(level)")
                .font(ElfFonts.Component.heroLevel)
                .foregroundStyle(ElfColors.Text.secondary)

            Text(name)
                .font(ElfFonts.Component.heroName)
                .bold()
                .foregroundStyle(ElfColors.Text.primary)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name), level \(level)")
    }
}

#Preview {
    VStack(alignment: .leading) {
        SquadCellHeader(level: 1, name: "Kirito")
        SquadCellHeader(level: 12, name: "Aerin Whitestar")
    }
    .padding()
    .background(Color.white.opacity(0.8))
}
