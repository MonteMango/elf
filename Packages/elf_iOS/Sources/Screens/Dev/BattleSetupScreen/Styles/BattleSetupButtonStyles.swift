//
//  BattleSetupButtonStyles.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 13.11.25.
//

import SwiftUI

// MARK: - Fight Style Button Style
struct FightStyleButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: BattleSetupConstants.Sizing.fightStyleButtonSize,
                   height: BattleSetupConstants.Sizing.fightStyleButtonSize)
            .background(isSelected ? BattleSetupConstants.Colors.buttonSelectedBackground : BattleSetupConstants.Colors.buttonNormalBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(
                        isSelected ? BattleSetupConstants.Colors.buttonSelectedBorder : BattleSetupConstants.Colors.buttonNormalBorder,
                        lineWidth: isSelected ? BattleSetupConstants.Sizing.selectedButtonBorderWidth : BattleSetupConstants.Sizing.buttonBorderWidth
                    )
            )
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}

// MARK: - Level Button Style
struct LevelButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: BattleSetupConstants.Sizing.levelButtonSize,
                   height: BattleSetupConstants.Sizing.levelButtonSize)
            .background(
                configuration.isPressed ?
                BattleSetupConstants.Colors.buttonHighlightedBackground :
                BattleSetupConstants.Colors.buttonNormalBackground
            )
            .cornerRadius(BattleSetupConstants.Sizing.levelButtonCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: BattleSetupConstants.Sizing.levelButtonCornerRadius)
                    .stroke(BattleSetupConstants.Colors.buttonNormalBorder, lineWidth: BattleSetupConstants.Sizing.buttonBorderWidth)
            )
    }
}

// MARK: - Item Button Style
struct ItemButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: BattleSetupConstants.Sizing.itemButtonSize,
                   height: BattleSetupConstants.Sizing.itemButtonSize)
            .background(
                configuration.isPressed ?
                BattleSetupConstants.Colors.buttonHighlightedBackground :
                BattleSetupConstants.Colors.buttonNormalBackground
            )
            .overlay(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(BattleSetupConstants.Colors.buttonNormalBorder, lineWidth: BattleSetupConstants.Sizing.buttonBorderWidth)
            )
    }
}

// MARK: - Jewelry Button Style
struct JewelryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: BattleSetupConstants.Sizing.jewelryButtonSize,
                   height: BattleSetupConstants.Sizing.jewelryButtonSize)
            .background(
                configuration.isPressed ?
                BattleSetupConstants.Colors.buttonHighlightedBackground :
                BattleSetupConstants.Colors.buttonNormalBackground
            )
            .overlay(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(BattleSetupConstants.Colors.buttonNormalBorder, lineWidth: BattleSetupConstants.Sizing.buttonBorderWidth)
            )
    }
}
