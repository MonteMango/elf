//
//  BattleResultHeader.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 11.12.25.
//

import elf_Kit
import elf_SwiftUI
import SwiftUI

struct BattleResultHeader: View {
    let outcome: BattleOutcome
    let isVisible: Bool

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: ElfSizing.BattleResult.smallSpacing) {
            // Outcome icon
            outcomeIcon
                .font(.system(size: ElfSizing.BattleResult.outcomeIconSize))
                .foregroundStyle(outcomeColor(for: outcome))

            // Outcome title
            Text(title(for: outcome))
                .font(ElfFonts.Component.outcomeTitle)
                .foregroundStyle(outcomeColor(for: outcome))
        }
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

    private func outcomeColor(for outcome: BattleOutcome) -> Color {
        switch outcome {
        case .victory:
            return ElfColors.Battle.victory
        case .defeat:
            return ElfColors.Battle.defeat
        case .draw:
            return ElfColors.Battle.draw
        }
    }

    private func title(for outcome: BattleOutcome) -> String {
        switch outcome {
        case .victory:
            return "VICTORY"
        case .defeat:
            return "DEFEAT"
        case .draw:
            return "DRAW"
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
