//
//  ArmorDisplay.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 13.11.25.
//

import SwiftUI
import elf_Kit

struct ArmorDisplay: View {
    @Binding var armorValues: [BodyPart: Int16]

    var body: some View {
        GeometryReader { geometry in
            let iconSize = BattleSetupConstants.Sizing.armorIconSize
            let centerX = geometry.size.width / 2
            let centerY = geometry.size.height / 2

            ZStack {
                // Center
                armorIcon(for: .body, value: armorValues[.body] ?? 0)
                    .position(x: centerX, y: centerY)

                // Top
                armorIcon(for: .head, value: armorValues[.head] ?? 0)
                    .position(x: centerX, y: centerY - iconSize - 10)

                // Bottom
                armorIcon(for: .legs, value: armorValues[.legs] ?? 0)
                    .position(x: centerX, y: centerY + iconSize + 10)

                // Left
                armorIcon(for: .leftHand, value: armorValues[.leftHand] ?? 0)
                    .position(x: centerX - iconSize - 10, y: centerY)

                // Right
                armorIcon(for: .rightHand, value: armorValues[.rightHand] ?? 0)
                    .position(x: centerX + iconSize + 10, y: centerY)
            }
        }
    }

    @ViewBuilder
    private func armorIcon(for bodyPart: BodyPart, value: Int16) -> some View {
        ZStack {
            Image(systemName: "shield.fill")
                .resizable()
                .frame(width: BattleSetupConstants.Sizing.armorIconSize,
                       height: BattleSetupConstants.Sizing.armorIconSize)
                .foregroundColor(BattleSetupConstants.Colors.armorOverlayTint)

            Text("\(value)")
                .font(.system(size: 8, weight: .regular))
                .foregroundColor(.white)
        }
    }
}

struct ArmorDisplay_Previews: PreviewProvider {
    static var previews: some View {
        ArmorDisplay(armorValues: .constant([
            .body: 10,
            .head: 5,
            .legs: 8,
            .leftHand: 7,
            .rightHand: 6
        ]))
        .frame(width: 200, height: 200)
        .background(Color.black)
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Armor Display")
    }
}
