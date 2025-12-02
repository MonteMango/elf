//
//  BuffsScrollView.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 28.11.25.
//

import SwiftUI

struct BuffsScrollView: View {
    let buffs: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: GameDayConstants.Spacing.smallSpacing) {
                if buffs.isEmpty {
                    // Placeholder empty slots
                    ForEach(0..<2, id: \.self) { _ in
                        buffSlot(isEmpty: true)
                    }
                } else {
                    ForEach(buffs, id: \.self) { buff in
                        buffSlot(isEmpty: false, buffName: buff)
                    }
                }
            }
        }
        .frame(height: GameDayConstants.Sizing.buffSize)
    }

    @ViewBuilder
    private func buffSlot(isEmpty: Bool, buffName: String? = nil) -> some View {
        RoundedRectangle(cornerRadius: 0)
            .fill(GameDayConstants.Colors.buffBackground)
            .frame(
                width: GameDayConstants.Sizing.buffSize,
                height: GameDayConstants.Sizing.buffSize
            )
            .overlay(
                Group {
                    if let name = buffName {
                        Text(String(name.prefix(1)))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(GameDayConstants.Colors.primaryText)
                    }
                }
            )
    }
}

#Preview {
    VStack {
        BuffsScrollView(buffs: [])
        BuffsScrollView(buffs: ["Strength", "Speed", "Defense"])
    }
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}
