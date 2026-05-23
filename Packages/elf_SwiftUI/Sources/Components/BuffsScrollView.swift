//
//  BuffsScrollView.swift
//  elf_SwiftUI
//
//  Created by Vitalii Lytvynov
//

import SwiftUI

public struct BuffsScrollView: View {

    // MARK: - Properties

    let buffs: [String]

    // MARK: - Init

    public init(buffs: [String]) {
        self.buffs = buffs
    }

    // MARK: - Body

    public var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        ScrollView(.horizontal) {
            HStack(spacing: ElfSpacing.component) {
                if buffs.isEmpty {
                    noBuffsPill
                } else {
                    ForEach(buffs, id: \.self) { buff in
                        buffSlot(buffName: buff)
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
        .frame(height: ElfSizing.GameDay.buffSize)
    }

    // MARK: - Subviews

    private var noBuffsPill: some View {
        Text("no buffs")
            .font(ElfFonts.Component.statLabel)
            .foregroundStyle(ElfColors.Text.secondary)
            .padding(.horizontal, ElfSpacing.small)
            .frame(height: ElfSizing.GameDay.buffSize)
            .overlay(
                RoundedRectangle(cornerRadius: ElfSizing.GameDay.buffSize / 2)
                    .stroke(ElfColors.Interactive.border, lineWidth: 1)
            )
    }

    @ViewBuilder
    private func buffSlot(buffName: String) -> some View {
        RoundedRectangle(cornerRadius: 0)
            .fill(ElfColors.Interactive.slotBackground)
            .frame(
                width: ElfSizing.GameDay.buffSize,
                height: ElfSizing.GameDay.buffSize
            )
            .overlay(
                Text(String(buffName.prefix(1)))
                    .font(ElfFonts.Component.statValue)
                    .foregroundStyle(ElfColors.Text.primaryLight)
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
