//
//  FightStyleSelector.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 13.11.25.
//

import SwiftUI
import elf_Kit

struct FightStyleSelector: View {
    @Binding var selectedFightStyle: FightStyle?

    private let fightStyles: [FightStyle] = [.dodge, .crit, .def]

    var body: some View {
        HStack(spacing: BattleSetupConstants.Spacing.fightStyleButtonSpacing) {
            ForEach(fightStyles, id: \.self) { style in
                Button(action: { selectedFightStyle = style }) {
                    fightStyleIcon(for: style)
                        .foregroundColor(.white)
                }
                .buttonStyle(FightStyleButtonStyle(isSelected: selectedFightStyle == style))
            }
        }
    }

    @ViewBuilder
    private func fightStyleIcon(for style: FightStyle) -> some View {
        switch style {
        case .dodge:
            Image(systemName: "wind")
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
        case .crit:
            Image(systemName: "bolt.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
        case .def:
            Image(systemName: "shield.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
        }
    }
}

// MARK: - Preview

struct FightStyleSelector_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Preview with Crit selected
            VStack(spacing: 20) {
                Text("Crit Selected")
                    .foregroundColor(.white)
                FightStyleSelector(selectedFightStyle: .constant(.crit))
            }
            .padding()
            .background(Color.black)
            .previewDisplayName("Crit Selected")

            // Preview with no selection
            VStack(spacing: 20) {
                Text("No Selection")
                    .foregroundColor(.white)
                FightStyleSelector(selectedFightStyle: .constant(nil))
            }
            .padding()
            .background(Color.black)
            .previewDisplayName("No Selection")

            // Preview with Dodge selected
            VStack(spacing: 20) {
                Text("Dodge Selected")
                    .foregroundColor(.white)
                FightStyleSelector(selectedFightStyle: .constant(.dodge))
            }
            .padding()
            .background(Color.black)
            .previewDisplayName("Dodge Selected")
        }
        .previewLayout(.sizeThatFits)
    }
}
