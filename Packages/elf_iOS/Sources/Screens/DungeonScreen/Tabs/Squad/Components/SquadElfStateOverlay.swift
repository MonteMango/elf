//
//  SquadElfStateOverlay.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import elf_SwiftUI
import SwiftUI

/// Visual wrapper that applies alive/dead/escaped affordances to a Squad cell.
/// In MVP every member is `.alive`, but the wrapper is in place so the
/// transitions land without view-level changes once domain runtime state arrives.
struct SquadElfStateOverlay<Content: View>: View {
    let state: DungeonSquadMemberDetail.State
    @ViewBuilder let content: Content

    var body: some View {
        content
            .opacity(opacityForState)
            .overlay(alignment: .center) {
                if let bandTitle {
                    Text(bandTitle)
                        .font(ElfFonts.Component.statLabel)
                        .bold()
                        .tracking(2)
                        .foregroundStyle(ElfColors.Background.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, ElfSpacing.xxs)
                        .background(bandColor)
                }
            }
            .allowsHitTesting(state == .alive)
    }

    private var opacityForState: Double {
        switch state {
        case .alive:   return 1.0
        case .dead:    return ElfOpacity.SquadCell.dead
        case .escaped: return ElfOpacity.SquadCell.escaped
        }
    }

    private var bandTitle: String? {
        switch state {
        case .alive:   return nil
        case .dead:    return "DEAD"
        case .escaped: return "ESCAPED"
        }
    }

    private var bandColor: Color {
        switch state {
        case .alive, .dead: return ElfColors.Text.primary
        case .escaped:      return ElfColors.Text.secondary
        }
    }
}
