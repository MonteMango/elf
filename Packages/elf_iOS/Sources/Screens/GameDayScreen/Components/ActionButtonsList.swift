//
//  ActionButtonsList.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 28.11.25.
//

import SwiftUI
import elf_Kit

struct ActionButtonsList: View {
    let onAction: (ActionType) -> Void

    var body: some View {
//        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: GameDayConstants.Spacing.buttonSpacing) {
                ForEach(ActionType.allCases, id: \.self) { action in
                    actionButton(for: action)
                }
            }
//        }
    }

    @ViewBuilder
    private func actionButton(for action: ActionType) -> some View {
        Button {
            onAction(action)
        } label: {
            Text(action.rawValue)
                .font(GameDayConstants.Fonts.buttonFont)
                .foregroundColor(GameDayConstants.Colors.actionButtonText)
                .frame(
                    width: GameDayConstants.Sizing.actionButtonWidth,
                    height: GameDayConstants.Sizing.actionButtonHeight
                )
                .background(GameDayConstants.Colors.actionButtonBackground)
                .cornerRadius(GameDayConstants.Sizing.actionButtonCornerRadius)
        }
    }
}

#Preview {
    ActionButtonsList(onAction: { _ in })
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
}
