//
//  CharacterSummaryView.swift
//  elf_iOS
//
//  Created by Claude on 23.11.25.
//

import elf_Kit
import SwiftUI

/// Stage 4: Character summary and finalization
struct CharacterSummaryView: View {
    let appearance: CharacterAppearance?
    let name: String
    let fightStyle: FightStyle?
    let fightStyleAttributes: HeroAttributes?
    let randomAttributes: HeroAttributes?
    let isCharacterReady: Bool
    let safeAreaInsets: EdgeInsets

    var body: some View {
        StageContainer(safeAreaInsets: safeAreaInsets) { size, safeArea in
            let padding: CGFloat = 10
            let availableHeight = size.height - padding * 2
            let cardHeight = availableHeight
            let cardWidth = cardHeight * 0.55

            HStack(alignment: .top, spacing: 40) {
                // Character image
                if let appearance = appearance {
                    Image(appearance.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: cardWidth, height: cardHeight)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(radius: 3)
                }

                // Character info
                VStack(alignment: .leading, spacing: 10) {
                    // Name and level
                    HStack(alignment: .firstTextBaseline) {
                        Text(name)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .lineLimit(nil)

                        Text("LVL1")
                            .font(.title3)
                            .foregroundColor(.gray)
                    }

                    // Fight style
                    if let style = fightStyle {
                        HStack {
                            Text("Fight style:")
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                            Text(style.displayName)
                                .foregroundColor(.black)
                        }
                    }

                    // Attributes
                    Text("Attributes:")
                        .fontWeight(.bold)
                        .foregroundColor(.black)

                    attributesView
                }
            }
            .padding(.vertical, padding)
            .padding(.leading, StagePadding.leading(safeArea))
            .padding(.trailing, StagePadding.trailing(safeArea))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    @ViewBuilder
    private var attributesView: some View {
        if let attrs = fightStyleAttributes {
            VStack(alignment: .leading, spacing: 8) {
                attributeRow("Strength", base: attrs.strength, bonus: randomAttributes?.strength)
                attributeRow("Agility", base: attrs.agility, bonus: randomAttributes?.agility)
                attributeRow("Power", base: attrs.power, bonus: randomAttributes?.power)
                attributeRow("Instinct", base: attrs.instinct, bonus: randomAttributes?.instinct)

                Spacer().frame(height: 8)

                attributeRow("HP", base: attrs.hitPoints, bonus: randomAttributes?.hitPoints)
                attributeRow("MP", base: attrs.manaPoints, bonus: randomAttributes?.manaPoints)
            }
        }
    }

    @ViewBuilder
    private func attributeRow(_ label: String, base: Int16, bonus: Int16?) -> some View {
        HStack {
            Text("- \(label):")
                .frame(width: 100, alignment: .leading)
                .foregroundColor(.black)

            let total = base + (bonus ?? 0)
            Text("\(total)")
                .frame(width: 30, alignment: .trailing)
                .foregroundColor(.black)

            Group {
                if let bonus = bonus, bonus > 0 {
                    Text("+\(bonus)")
                        .foregroundColor(.green)
                } else {
                    Text("")
                }
            }
            .frame(width: 50, alignment: .leading)
        }
    }
}

#Preview("Before Ready") {
    CharacterSummaryView(
        appearance: .appearance1,
        name: "Asuna Yuuki",
        fightStyle: .dodge,
        fightStyleAttributes: HeroAttributes(
            hitPoints: 80,
            manaPoints: 20,
            agility: 4,
            strength: 1,
            power: 0,
            instinct: 1
        ),
        randomAttributes: nil,
        isCharacterReady: false,
        safeAreaInsets: EdgeInsets()
    )
}

#Preview("After Ready") {
    CharacterSummaryView(
        appearance: .appearance1,
        name: "Asuna Yuuki",
        fightStyle: .dodge,
        fightStyleAttributes: HeroAttributes(
            hitPoints: 80,
            manaPoints: 20,
            agility: 4,
            strength: 1,
            power: 0,
            instinct: 1
        ),
        randomAttributes: HeroAttributes(
            hitPoints: 0,
            manaPoints: 0,
            agility: 2,
            strength: 1,
            power: 1,
            instinct: 0
        ),
        isCharacterReady: true,
        safeAreaInsets: EdgeInsets()
    )
}
