//
//  CraftCategoryButtonsRow.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import elf_SwiftUI
import SwiftUI

struct CraftCategoryButtonsRow: View {
    let selectedCategory: CraftCategory
    let onCategoryTap: (CraftCategory) -> Void

    var body: some View {
        HStack(spacing: ElfSpacing.medium) {
            ForEach(CraftCategory.allCases) { category in
                CraftCategoryButton(
                    title: category.displayTitle,
                    isSelected: category == selectedCategory,
                    size: ElfSizing.Craft.categoryButtonSize,
                    onTap: { onCategoryTap(category) }
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

// MARK: - Craft Category Button

private struct CraftCategoryButton: View {
    let title: String
    let isSelected: Bool
    let size: CGFloat
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(isSelected ? ElfColors.primary : ElfColors.Background.primary)

                Text(title)
                    .font(ElfFonts.Component.categoryTab)
                    .foregroundStyle(isSelected ? ElfColors.Text.primaryLight : ElfColors.Text.accent)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(ElfSpacing.component)
            }
            .frame(width: size, height: size)
            .elfShadow(ElfShadows.medium)
        }
        .buttonStyle(.plain)
    }
}
