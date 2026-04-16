//
//  SubcategoryButtonsRow.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_SwiftUI
import SwiftUI

struct SubcategoryButtonsRow: View {
    let titles: [String]
    let selectedIndex: Int
    let onSubcategoryTap: (Int) -> Void

    private let buttonSize: CGFloat = 40

    var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        HStack(spacing: 10) {
            ForEach(Array(titles.enumerated()), id: \.offset) { index, title in
                SubcategoryButton(
                    title: title,
                    isSelected: index == selectedIndex,
                    size: buttonSize,
                    onTap: { onSubcategoryTap(index) }
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Subcategory Button

private struct SubcategoryButton: View {
    let title: String
    let isSelected: Bool
    let size: CGFloat
    let onTap: () -> Void

    var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(isSelected ? Color.orange : Color.white)

                Text(title)
                    .font(ElfFonts.Component.subcategoryTab)
                    .foregroundStyle(isSelected ? .white : .orange)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(4)
            }
            .frame(width: size, height: size)
            .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 20) {
        SubcategoryButtonsRow(
            titles: ["all", "one hand", "two\nhands", "shields"],
            selectedIndex: 0,
            onSubcategoryTap: { _ in }
        )

        SubcategoryButtonsRow(
            titles: ["all", "armor", "jewelry"],
            selectedIndex: 1,
            onSubcategoryTap: { _ in }
        )
    }
    .padding()
    .background(Color.white)
}
