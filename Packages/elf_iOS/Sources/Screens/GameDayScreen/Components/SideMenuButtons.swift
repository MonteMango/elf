//
//  SideMenuButtons.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 28.11.25.
//

import elf_Kit
import elf_SwiftUI
import SwiftUI

struct SideMenuButtons: View {
    let onMenuTapped: (SideMenuType) -> Void

    // Define grid layout: 2 columns
    private let columns = [
        GridItem(.fixed(ElfSizing.Button.sideSize), spacing: ElfSpacing.button),
        GridItem(.fixed(ElfSizing.Button.sideSize), spacing: ElfSpacing.button)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: ElfSpacing.button) {
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
            VStack(spacing: ElfSpacing.xxs) {
                RoundedRectangle(cornerRadius: ElfSizing.GameDay.sideButtonCornerRadius)
                    .fill(ElfColors.Button.primary)
                    .frame(
                        width: ElfSizing.Button.sideSize,
                        height: ElfSizing.Button.sideSize
                    )

                Text(menu.rawValue)
                    .font(ElfFonts.Component.sideButton)
                    .foregroundColor(ElfColors.Text.secondary)
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
