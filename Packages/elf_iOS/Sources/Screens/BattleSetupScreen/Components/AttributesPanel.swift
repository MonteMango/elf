//
//  AttributesPanel.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 13.11.25.
//

import SwiftUI
import elf_Kit

// MARK: - AttributesPanel

struct AttributesPanel: View {

    // MARK: - Properties

    let alignment: HorizontalAlignment
    let attributes: HeroAttributes?
    let fightStyleAttrs: HeroAttributes?
    let levelAttrs: HeroAttributes?
    let itemsAttrs: HeroAttributes?
    let leftHandDamage: (minDmg: Int16, maxDmg: Int16)?
    let rightHandDamage: (minDmg: Int16, maxDmg: Int16)?

    // MARK: - Body

    var body: some View {
        VStack(alignment: alignment, spacing: BattleSetupConstants.Spacing.attributeRowSpacing) {
            // Group 1: Basic attributes
            attributeRow(
                title: "Strength",
                value: attributes?.strength ?? 0,
                breakdown: (
                    fightStyleAttrs?.strength ?? 0,
                    levelAttrs?.strength ?? 0,
                    itemsAttrs?.strength ?? 0
                )
            )

            attributeRow(
                title: "Agility",
                value: attributes?.agility ?? 0,
                breakdown: (
                    fightStyleAttrs?.agility ?? 0,
                    levelAttrs?.agility ?? 0,
                    itemsAttrs?.agility ?? 0
                )
            )

            attributeRow(
                title: "Power",
                value: attributes?.power ?? 0,
                breakdown: (
                    fightStyleAttrs?.power ?? 0,
                    levelAttrs?.power ?? 0,
                    itemsAttrs?.power ?? 0
                )
            )

            attributeRow(
                title: "Instinct",
                value: attributes?.instinct ?? 0,
                breakdown: (
                    fightStyleAttrs?.instinct ?? 0,
                    levelAttrs?.instinct ?? 0,
                    itemsAttrs?.instinct ?? 0
                )
            )

            // Group 2: Attack attributes
            // Att 1 - Right hand
            HStack(spacing: 8) {
                if alignment == .leading {
                    Text("Att 1")
                        .font(BattleSetupConstants.Fonts.labelFont)
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(rightHandDamage?.minDmg ?? 0)-\(rightHandDamage?.maxDmg ?? 0)")
                        .font(BattleSetupConstants.Fonts.attributeTotal)
                        .foregroundColor(BattleSetupConstants.Colors.attributeTotalText)
                } else {
                    Text("\(rightHandDamage?.minDmg ?? 0)-\(rightHandDamage?.maxDmg ?? 0)")
                        .font(BattleSetupConstants.Fonts.attributeTotal)
                        .foregroundColor(BattleSetupConstants.Colors.attributeTotalText)
                    Spacer()
                    Text("Att 1")
                        .font(BattleSetupConstants.Fonts.labelFont)
                        .foregroundColor(.white)
                }
            }

            // Att 2 - Left hand
            HStack(spacing: 8) {
                if alignment == .leading {
                    Text("Att 2")
                        .font(BattleSetupConstants.Fonts.labelFont)
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(leftHandDamage?.minDmg ?? 0)-\(leftHandDamage?.maxDmg ?? 0)")
                        .font(BattleSetupConstants.Fonts.attributeTotal)
                        .foregroundColor(BattleSetupConstants.Colors.attributeTotalText)
                } else {
                    Text("\(leftHandDamage?.minDmg ?? 0)-\(leftHandDamage?.maxDmg ?? 0)")
                        .font(BattleSetupConstants.Fonts.attributeTotal)
                        .foregroundColor(BattleSetupConstants.Colors.attributeTotalText)
                    Spacer()
                    Text("Att 2")
                        .font(BattleSetupConstants.Fonts.labelFont)
                        .foregroundColor(.white)
                }
            }

            // Group 3: Resource attributes
            attributeRow(
                title: "HP",
                value: attributes?.hitPoints ?? 0,
                breakdown: (
                    fightStyleAttrs?.hitPoints ?? 0,
                    levelAttrs?.hitPoints ?? 0,
                    itemsAttrs?.hitPoints ?? 0
                )
            )

            attributeRow(
                title: "MP",
                value: attributes?.manaPoints ?? 0,
                breakdown: (
                    fightStyleAttrs?.manaPoints ?? 0,
                    levelAttrs?.manaPoints ?? 0,
                    itemsAttrs?.manaPoints ?? 0
                )
            )
        }
    }

    // MARK: - Private Methods

    @ViewBuilder
    private func attributeRow(
        title: String,
        value: Int16,
        breakdown: (fightStyle: Int16, level: Int16, items: Int16)
    ) -> some View {
        AttributeRow(
            title: title,
            total: value,
            breakdown: breakdown,
            alignment: alignment
        )
    }
}

// MARK: - Preview

struct AttributesPanel_Previews: PreviewProvider {
    static var previews: some View {
        let mockTotalAttributes = HeroAttributes(
            hitPoints: 170,
            manaPoints: 85,
            agility: 33,
            strength: 43,
            power: 18,
            instinct: 24
        )

        let mockFightStyle = HeroAttributes(
            hitPoints: 20,
            manaPoints: 10,
            agility: 5,
            strength: 8,
            power: 3,
            instinct: 4
        )

        let mockLevel = HeroAttributes(
            hitPoints: 100,
            manaPoints: 50,
            agility: 15,
            strength: 20,
            power: 10,
            instinct: 12
        )

        let mockItems = HeroAttributes(
            hitPoints: 50,
            manaPoints: 25,
            agility: 13,
            strength: 15,
            power: 5,
            instinct: 8
        )

        Group {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Player Panel (Leading)")
                        .foregroundColor(.white)
                        .font(.caption)
                    AttributesPanel(
                        alignment: .leading,
                        attributes: mockTotalAttributes,
                        fightStyleAttrs: mockFightStyle,
                        levelAttrs: mockLevel,
                        itemsAttrs: mockItems,
                        leftHandDamage: (minDmg: 5, maxDmg: 12),
                        rightHandDamage: (minDmg: 15, maxDmg: 30)
                    )
                }
                .padding()
                .background(Color.black)
            }
            .previewDisplayName("Player Panel")

            ScrollView {
                VStack(spacing: 20) {
                    Text("Bot Panel (Trailing)")
                        .foregroundColor(.white)
                        .font(.caption)
                    AttributesPanel(
                        alignment: .trailing,
                        attributes: mockTotalAttributes,
                        fightStyleAttrs: mockFightStyle,
                        levelAttrs: mockLevel,
                        itemsAttrs: mockItems,
                        leftHandDamage: (minDmg: 8, maxDmg: 18),
                        rightHandDamage: (minDmg: 12, maxDmg: 25)
                    )
                }
                .padding()
                .background(Color.black)
            }
            .previewDisplayName("Bot Panel")
        }
        .previewLayout(.sizeThatFits)
    }
}
