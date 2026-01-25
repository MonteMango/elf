//
//  BuffsScrollView.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 28.11.25.
//

import elf_SwiftUI
import SwiftUI

struct BuffsScrollView: View {
    let buffs: [String]

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: ElfSpacing.component) {
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
        .scrollIndicators(.hidden)
        .frame(height: ElfSizing.GameDay.buffSize)
    }

    @ViewBuilder
    private func buffSlot(isEmpty: Bool, buffName: String? = nil) -> some View {
        RoundedRectangle(cornerRadius: 0)
            .fill(ElfColors.Interactive.slotBackground)
            .frame(
                width: ElfSizing.GameDay.buffSize,
                height: ElfSizing.GameDay.buffSize
            )
            .overlay(
                Group {
                    if let name = buffName {
                        Text(String(name.prefix(1)))
                            .font(ElfFonts.Component.statValue)
                            .foregroundStyle(ElfColors.Text.primaryLight)
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
