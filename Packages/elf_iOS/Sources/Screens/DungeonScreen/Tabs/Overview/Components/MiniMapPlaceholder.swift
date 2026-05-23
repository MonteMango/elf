//
//  MiniMapPlaceholder.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_SwiftUI
import SwiftUI

/// Stand-in for the real dungeon mini-map. Gray rounded rectangle with a
/// `miniMap` label centered. Replace this view with the actual graph
/// visualisation when `DungeonRoomScreen` and the map renderer land.
struct MiniMapPlaceholder: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: ElfCornerRadius.medium)
                .fill(Color.gray.opacity(0.4))

            Text("miniMap")
                .font(ElfFonts.caption)
                .fontWeight(.semibold)
                .foregroundStyle(ElfColors.Text.primaryLight)
        }
        .frame(height: 80)
    }
}
