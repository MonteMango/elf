//
//  DungeonMapContent.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import elf_SwiftUI
import SwiftUI

/// Map-tab body of `DungeonScreen`. Placeholder for now — future commits
/// will render the dungeon room graph with branch / merge points and party
/// position tracking for splitPath / randomPath dungeons.
struct DungeonMapContent: View {
    @State private var viewModel: DungeonMapViewModel

    init(session: DungeonSession) {
        self._viewModel = State(initialValue: session.makeMapViewModel())
    }

    var body: some View {
        Text("Map — coming next (\(viewModel.dungeon?.rooms.count ?? 0) rooms)")
            .font(ElfFonts.title2)
            .foregroundStyle(ElfColors.Text.primaryLight)
    }
}
