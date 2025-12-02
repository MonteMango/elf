//
//  PocketsView.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 28.11.25.
//

import SwiftUI

struct PocketsView: View {
    let onPocketTapped: (Int) -> Void

    var body: some View {
        HStack(spacing: GameDayConstants.Spacing.buttonSpacing) {
            ForEach(0..<4, id: \.self) { index in
                pocketSlot(index: index)
            }
        }
    }

    @ViewBuilder
    private func pocketSlot(index: Int) -> some View {
        Button {
            onPocketTapped(index)
        } label: {
            Circle()
                .fill(GameDayConstants.Colors.pocketBackground)
                .frame(
                    width: GameDayConstants.Sizing.pocketSize,
                    height: GameDayConstants.Sizing.pocketSize
                )
                .overlay(
                    Circle()
                        .stroke(GameDayConstants.Colors.pocketBorder, lineWidth: 1)
                )
        }
    }
}

#Preview {
    PocketsView(onPocketTapped: { _ in })
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
}
