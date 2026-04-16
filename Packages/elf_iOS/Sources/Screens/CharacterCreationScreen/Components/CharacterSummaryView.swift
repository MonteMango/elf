//
//  CharacterSummaryView.swift
//  elf_iOS
//
//  Created by Claude on 23.11.25.
//

import elf_Kit
import elf_SwiftUI
import SwiftUI

/// Stage 4: Character summary and finalization
struct CharacterSummaryView: View {
    let appearance: CharacterAppearance?
    let name: String
    let fightStyle: FightStyle?
    let fightStyleAttributes: HeroAttributes?
    let randomAttributes: HeroAttributes?
    let isCharacterReady: Bool
    let assignedHouse: House?
    let safeAreaInsets: EdgeInsets

    var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        StageContainer(safeAreaInsets: safeAreaInsets) { size, safeArea in
            let padding: CGFloat = 10
            let availableHeight = size.height - padding * 2
            let cardHeight = availableHeight
            let cardWidth = cardHeight * 0.55

            HStack(alignment: .top, spacing: 0) {
                // House info (left side)
                if isCharacterReady {
                    houseInfoView(cardHeight: cardHeight)
                        .frame(maxWidth: .infinity)
                }

                HStack(alignment: .top, spacing: 20) {
                    // Character image
                    if let appearance = appearance {
                        Image(appearance.imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: cardWidth, height: cardHeight)
                            .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
                            .shadow(radius: 3)
                    }

                    // Character info
                    VStack(alignment: .leading, spacing: 10) {
                        // Name and level
                        HStack(alignment: .firstTextBaseline) {
                            Text(name)
                                .font(ElfFonts.Component.characterName)
                                .foregroundStyle(.black)
                                .lineLimit(nil)

                            Text("LVL1")
                                .font(ElfFonts.Component.characterLevel)
                                .foregroundStyle(.gray)
                        }

                        // Fight style
                        if let style = fightStyle {
                            HStack {
                                Text("Fight style:")
                                    .bold()
                                    .foregroundStyle(.black)
                                Text(style.displayName)
                                    .foregroundStyle(.black)
                            }
                        }

                        // Attributes
                        Text("Attributes:")
                            .bold()
                            .foregroundStyle(.black)

                        attributesView
                    }
                }
                .frame(width: 450)

                if isCharacterReady {
                    Spacer()
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, StagePadding.top())
            .padding(.leading, StagePadding.leading(safeArea))
            .padding(.trailing, StagePadding.trailing(safeArea))
            .padding(.bottom, StagePadding.bottom(safeArea))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    @ViewBuilder
    private func houseInfoView(cardHeight: CGFloat) -> some View {
        VStack(spacing: 12) {
            Text("Your House")
                .font(.headline)
                .foregroundStyle(.black)

            if let house = assignedHouse {
                Image(house.logoImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .clipShape(.rect(cornerRadius: 8))

                Text(house.name)
                    .font(ElfFonts.Component.sectionTitle)
                    .foregroundStyle(.black)
            }
        }
        .frame(height: cardHeight, alignment: .top)
        .padding(.top, 20)
    }

    @ViewBuilder
    private var attributesView: some View {
        if let attrs = fightStyleAttributes {
            VStack(alignment: .leading, spacing: 8) {
                attributeRow("Strength", base: attrs.strength.value, bonus: randomAttributes?.strength.value)
                attributeRow("Agility", base: attrs.agility.value, bonus: randomAttributes?.agility.value)
                attributeRow("Power", base: attrs.power.value, bonus: randomAttributes?.power.value)
                attributeRow("Instinct", base: attrs.instinct.value, bonus: randomAttributes?.instinct.value)

                Spacer().frame(height: 8)

                attributeRow("HP", base: attrs.hitPoints.value, bonus: randomAttributes?.hitPoints.value)
                attributeRow("MP", base: attrs.manaPoints.value, bonus: randomAttributes?.manaPoints.value)
            }
        }
    }

    @ViewBuilder
    private func attributeRow(_ label: String, base: Int16, bonus: Int16?) -> some View {
        HStack {
            Text("- \(label):")
                .frame(width: 100, alignment: .leading)
                .foregroundStyle(.black)

            let total = base + (bonus ?? 0)
            Text("\(total)")
                .frame(width: 30, alignment: .trailing)
                .foregroundStyle(.black)

            Group {
                if let bonus = bonus, bonus > 0 {
                    Text("+\(bonus)")
                        .foregroundStyle(.green)
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
        assignedHouse: nil,
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
        assignedHouse: nil,
        safeAreaInsets: EdgeInsets()
    )
}
