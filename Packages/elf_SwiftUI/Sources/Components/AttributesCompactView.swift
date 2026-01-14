//
//  AttributesCompactView.swift
//  elf_SwiftUI
//
//  Created by Vitalii Lytvynov
//

import SwiftUI

public struct AttributesCompactView: View {

    // MARK: - Properties

    let strength: Int
    let agility: Int
    let power: Int
    let instinct: Int

    // MARK: - Init

    public init(strength: Int, agility: Int, power: Int, instinct: Int) {
        self.strength = strength
        self.agility = agility
        self.power = power
        self.instinct = instinct
    }

    // MARK: - Body

    public var body: some View {
        HStack(spacing: ElfSpacing.large + ElfSpacing.xxxs) {
            IconValueLabel(icon: "figure.strengthtraining.traditional", value: strength, color: ElfColors.Attributes.strength)
            IconValueLabel(icon: "figure.run", value: agility, color: ElfColors.Attributes.agility)
            IconValueLabel(icon: "bolt.fill", value: power, color: ElfColors.Attributes.power)
            IconValueLabel(icon: "eye.fill", value: instinct, color: ElfColors.Attributes.instinct)
        }
    }
}

#Preview {
    AttributesCompactView(
        strength: 10,
        agility: 12,
        power: 8,
        instinct: 15
    )
    .padding()
    .background(Color.white)
}
