//
//  BattleResultHeader.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 11.12.25.
//

import elf_Kit
import SwiftUI

struct BattleResultHeader: View {
    let outcome: BattleOutcome
    let isVisible: Bool

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: BattleResultConstants.Sizing.smallSpacing) {
            // Outcome icon
            outcomeIcon
                .font(.system(size: BattleResultConstants.Sizing.outcomeIconSize))
                .foregroundStyle(BattleResultConstants.color(for: outcome))

            // Outcome title
            Text(BattleResultConstants.title(for: outcome))
                .font(BattleResultConstants.Fonts.outcomeTitle)
                .foregroundStyle(BattleResultConstants.color(for: outcome))
        }
//        .frame(width: BattleResultConstants.Sizing.headerWidth)
        .scaleEffect(isVisible ? 1.0 : 0.5)
        .opacity(isVisible ? 1.0 : 0.0)
    }

    @ViewBuilder
    private var outcomeIcon: some View {
        switch outcome {
        case .victory:
            Image(systemName: "crown.fill")
        case .defeat:
            Image(systemName: "xmark.circle.fill")
        case .draw:
            Image(systemName: "equal.circle.fill")
        }
    }
}

#Preview("Victory") {
    ZStack {
        Color.black.ignoresSafeArea()
        BattleResultHeader(outcome: .victory, isVisible: true)
    }
}

#Preview("Defeat") {
    ZStack {
        Color.black.ignoresSafeArea()
        BattleResultHeader(outcome: .defeat, isVisible: true)
    }
}

#Preview("Draw") {
    ZStack {
        Color.black.ignoresSafeArea()
        BattleResultHeader(outcome: .draw, isVisible: true)
    }
}
