//
//  DungeonSquadContent.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import elf_SwiftUI
import SwiftUI

/// Squad-tab body of `DungeonScreen`. Placeholder for now — future commits
/// will render full per-elf detail (portrait, stats, equipped items, alive /
/// dead flags during a run).
struct DungeonSquadContent: View {
    @State private var viewModel: DungeonSquadViewModel

    init(session: GameSessionModel, dungeonId: UUID, allyIds: [UUID]) {
        self._viewModel = State(initialValue: session.makeDungeonSquadViewModel(
            dungeonId: dungeonId,
            allyIds: allyIds
        ))
    }

    var body: some View {
        Text("Squad — coming next (\(viewModel.squad.count) elves)")
            .font(ElfFonts.title2)
            .foregroundStyle(ElfColors.Text.primaryLight)
    }
}
