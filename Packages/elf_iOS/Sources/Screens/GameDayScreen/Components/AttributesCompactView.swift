//
//  AttributesCompactView.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 28.11.25.
//

import SwiftUI
import elf_Kit

struct AttributesCompactView: View {
    let attributes: HeroAttributes

    var body: some View {
        HStack(spacing: 15) {
            attributeItem(icon: "figure.strengthtraining.traditional", value: attributes.strength)
            attributeItem(icon: "figure.run", value: attributes.agility)
            attributeItem(icon: "bolt.fill", value: attributes.power)
            attributeItem(icon: "eye.fill", value: attributes.instinct)
        }
    }

    @ViewBuilder
    private func attributeItem(icon: String, value: Int16) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: GameDayConstants.Sizing.attributeIconSize))
                .foregroundColor(Color.gray)

            Text("\(value)")
                .font(GameDayConstants.Fonts.attributeValueFont)
                .foregroundColor(Color.black)
        }
    }
}

#Preview {
    AttributesCompactView(
        attributes: HeroAttributes(
            hitPoints: 83,
            manaPoints: 24,
            agility: 5,
            strength: 2,
            power: 1,
            instinct: 2
        )
    )
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}
