//
//  AttributeRow.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 13.11.25.
//

import SwiftUI

struct AttributeRow: View {
    let title: String
    let total: Int16
    let breakdown: (fightStyle: Int16, level: Int16, items: Int16)
    let alignment: HorizontalAlignment

    var body: some View {
        HStack(spacing: 8) {
            if alignment == .leading {
                Text(title)
                    .font(BattleSetupConstants.Fonts.labelFont)
                    .foregroundColor(.white)
                Spacer()
                formattedCalculation
            } else {
                formattedCalculation
                Spacer()
                Text(title)
                    .font(BattleSetupConstants.Fonts.labelFont)
                    .foregroundColor(.white)
            }
        }
    }

    private var formattedCalculation: some View {
        Group {
            if alignment == .leading {
                // Player format: "X A+B+C" (X=total bold orange, A+B+C=breakdown white)
                Text(String(total))
                    .font(BattleSetupConstants.Fonts.attributeTotal)
                    .foregroundColor(BattleSetupConstants.Colors.attributeTotalText)
                +
                Text(" ")
                +
                Text("\(breakdown.fightStyle)+\(breakdown.level)+\(breakdown.items)")
                    .font(BattleSetupConstants.Fonts.attributeBreakdown)
                    .foregroundColor(BattleSetupConstants.Colors.attributeBreakdownText)
            } else {
                // Bot format: "A+B+C X" (A+B+C=breakdown white, X=total bold orange)
                Text("\(breakdown.items)+\(breakdown.level)+\(breakdown.fightStyle)")
                    .font(BattleSetupConstants.Fonts.attributeBreakdown)
                    .foregroundColor(BattleSetupConstants.Colors.attributeBreakdownText)
                +
                Text(" ")
                +
                Text(String(total))
                    .font(BattleSetupConstants.Fonts.attributeTotal)
                    .foregroundColor(BattleSetupConstants.Colors.attributeTotalText)
            }
        }
    }
}

// MARK: - Preview

struct AttributeRow_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VStack(spacing: 20) {
                Text("Player Format (Leading)")
                    .foregroundColor(.white)
                    .font(.caption)
                AttributeRow(
                    title: "Strength",
                    total: 100,
                    breakdown: (fightStyle: 20, level: 50, items: 30),
                    alignment: .leading
                )
                AttributeRow(
                    title: "HP",
                    total: 250,
                    breakdown: (fightStyle: 50, level: 150, items: 50),
                    alignment: .leading
                )
            }
            .padding()
            .background(Color.black)
            .previewDisplayName("Player Alignment")

            VStack(spacing: 20) {
                Text("Bot Format (Trailing)")
                    .foregroundColor(.white)
                    .font(.caption)
                AttributeRow(
                    title: "Strength",
                    total: 85,
                    breakdown: (fightStyle: 15, level: 40, items: 30),
                    alignment: .trailing
                )
                AttributeRow(
                    title: "HP",
                    total: 200,
                    breakdown: (fightStyle: 40, level: 120, items: 40),
                    alignment: .trailing
                )
            }
            .padding()
            .background(Color.black)
            .previewDisplayName("Bot Alignment")
        }
        .previewLayout(.sizeThatFits)
    }
}
