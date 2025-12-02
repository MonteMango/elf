//
//  SideMenuButtons.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 28.11.25.
//

import elf_Kit
import SwiftUI

struct SideMenuButtons: View {
    let onMenuTapped: (SideMenuType) -> Void

    // Define grid layout: 2 columns
    private let columns = [
        GridItem(.fixed(GameDayConstants.Sizing.sideButtonSize), spacing: GameDayConstants.Spacing.buttonSpacing),
        GridItem(.fixed(GameDayConstants.Sizing.sideButtonSize), spacing: GameDayConstants.Spacing.buttonSpacing)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: GameDayConstants.Spacing.buttonSpacing) {
            ForEach(SideMenuType.allCases, id: \.self) { menu in
                sideButton(for: menu)
            }
        }
    }

    @ViewBuilder
    private func sideButton(for menu: SideMenuType) -> some View {
        Button {
            onMenuTapped(menu)
        } label: {
            VStack(spacing: 4) {
                RoundedRectangle(cornerRadius: GameDayConstants.Sizing.sideButtonCornerRadius)
                    .fill(GameDayConstants.Colors.sideButtonBackground)
                    .frame(
                        width: GameDayConstants.Sizing.sideButtonSize,
                        height: GameDayConstants.Sizing.sideButtonSize
                    )

                Text(menu.rawValue)
                    .font(GameDayConstants.Fonts.sideButtonFont)
                    .foregroundColor(Color.gray)
            }
        }
    }
}

#Preview {
    SideMenuButtons(onMenuTapped: { _ in })
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
}
