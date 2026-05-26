//
//  BuffBadgeStripView.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import elf_SwiftUI
import SwiftUI

/// Horizontal row of active buff/debuff badges rendered under a combatant's
/// EP bar. Uses `AppliedBuff.id` for identity so a freshly-applied buff (e.g.
/// end-of-round `Exhausted`) animates in via `.transition` without disturbing
/// the surrounding badges.
struct BuffBadgeStripView: View {

    let badges: [BuffBadgeViewState]

    var body: some View {
        HStack(spacing: ElfSizing.BattleFight.buffBadgeSpacing) {
            ForEach(badges) { badge in
                BuffBadgeView(badge: badge)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.easeInOut(duration: 0.2), value: badges.map(\.id))
    }
}
