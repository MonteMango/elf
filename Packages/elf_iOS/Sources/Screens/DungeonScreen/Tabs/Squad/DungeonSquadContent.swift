//
//  DungeonSquadContent.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import elf_SwiftUI
import SwiftUI

/// Squad-tab body of `DungeonScreen`. Horizontal scroller of one cell per
/// elf — hero pinned first. Read-only briefing; equipment, ordering, and
/// squad composition are owned by `GameDayScreen`.
struct DungeonSquadContent: View {
    @State private var viewModel: DungeonSquadViewModel

    init(session: DungeonSession) {
        self._viewModel = State(initialValue: session.makeSquadViewModel())
    }

    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: ElfSpacing.medium) {
                ForEach(viewModel.squad) { member in
                    SquadElfCell(member: member)
                }
            }
            .scrollTargetLayout()
        }
        .scrollIndicators(.hidden)
        .scrollTargetBehavior(.viewAligned)
    }
}
