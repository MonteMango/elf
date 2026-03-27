//
//  FightStyleSelectionView.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 23.11.25.
//

import elf_Kit
import elf_SwiftUI
import SwiftUI

/// Stage 3: Select fight style
struct FightStyleSelectionView: View {
    @Binding var selectedFightStyle: FightStyle?
    let safeAreaInsets: EdgeInsets
    let fightStyleDescription: String?
    let fightStyleAttributesDescription: String?

    var body: some View {
        StageContainer(safeAreaInsets: safeAreaInsets) { _, safeArea in
            ZStack {
                // Title and buttons (top left)
                VStack(alignment: .leading, spacing: 20) {
                    Text("Select your fight style")
                        .font(ElfFonts.Component.sectionTitle)
                        .foregroundStyle(.black)
                        .padding(.top, StagePadding.top())
                        .padding(.leading, StagePadding.leading(safeArea))

                    // Fight style buttons (left, vertical)
                    VStack(spacing: 15) {
                        ForEach([FightStyle.dodge, .crit, .def], id: \.self) { style in
                            fightStyleButton(for: style)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, StagePadding.leading(safeArea))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                // Base attributes (center bottom)
                VStack(spacing: 8) {
                    Text("Base attributes")
                        .font(.headline)
                        .bold()
                        .foregroundStyle(.black)

                    if let description = fightStyleAttributesDescription {
                        Text(description)
                            .font(.body)
                            .foregroundStyle(.black)
                    } else {
                        Text("No style selected")
                            .font(.body)
                            .foregroundStyle(.gray)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)

                // Fight Tactic (top right corner)
                if let description = fightStyleDescription {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Fight Tactic")
                            .font(.headline)
                            .bold()
                            .foregroundStyle(.black)

                        Text(description)
                            .font(.footnote)
                            .foregroundStyle(.gray)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(width: 180, alignment: .leading)
                    .padding(.top, StagePadding.top())
                    .padding(.trailing, StagePadding.trailing(safeArea))
                    .padding(.bottom, 80)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                }
            }
        }
    }

    @ViewBuilder
    private func fightStyleButton(for style: FightStyle) -> some View {
        let isSelected = selectedFightStyle == style

        Button(action: {
            selectedFightStyle = style
        }) {
            Text(style.displayName)
                .font(ElfFonts.Component.sectionTitle)
                .foregroundStyle(.white)
                .frame(width: 150, height: 50)
                .background(styleColor(for: style), in: RoundedRectangle(cornerRadius: 8))
                .elfSelectionBorder(isSelected, cornerRadius: 8)
        }
    }

    private func styleColor(for style: FightStyle) -> Color {
        switch style {
        case .dodge:
            return .green
        case .crit:
            return .red
        case .def:
            return .blue
        }
    }
}

// MARK: - FightStyle Display Name Extension

extension FightStyle {
    var displayName: String {
        switch self {
        case .dodge:
            return "Dodge"
        case .crit:
            return "Crit"
        case .def:
            return "Def"
        }
    }
}

#Preview {
    FightStyleSelectionView(
        selectedFightStyle: .constant(.dodge),
        safeAreaInsets: EdgeInsets(),
        fightStyleDescription: "Your fight tactic is based on dodging enemy attacks.",
        fightStyleAttributesDescription: "Agility +4, Instinct +1, Strength +1"
    )
}
