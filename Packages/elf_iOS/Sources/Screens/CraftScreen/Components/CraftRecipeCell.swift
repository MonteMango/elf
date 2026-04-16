//
//  CraftRecipeCell.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import elf_SwiftUI
import SwiftUI

struct CraftRecipeCell: View {
    let item: CraftRecipeListItem
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        Button(action: onTap) {
            ZStack(alignment: .bottomTrailing) {
                HStack(spacing: ElfSpacing.medium) {
                    // Item image
                    Image(item.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: ElfSizing.Icon.xlarge, height: ElfSizing.Icon.xlarge)

                    // Title + short info
                    VStack(alignment: .leading, spacing: ElfSpacing.xxs) {
                        Text(item.title)
                            .font(ElfFonts.Component.itemTitle)
                            .foregroundStyle(ElfColors.Text.primary)

                        Text(item.shortInfo)
                            .font(ElfFonts.Component.itemDetail)
                            .foregroundStyle(ElfColors.Text.secondary)
                    }

                    Spacer()
                }

                // Ingredient badges pinned bottom-right
                HStack(spacing: ElfSpacing.xs) {
                    ForEach(item.ingredients) { ingredient in
                        HStack(spacing: ElfSpacing.xxxs) {
                            Image(ingredient.imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: ElfSizing.Craft.ingredientIconSize, height: ElfSizing.Craft.ingredientIconSize)
                            Text("x\(ingredient.amount)")
                                .font(ElfFonts.Component.ingredientCount)
                                .foregroundStyle(ElfColors.Text.secondary)
                        }
                    }
                }
            }
            .padding(ElfSpacing.small)
            .background {
                Rectangle()
                    .fill(ElfColors.Background.card)
            }
            .elfSelectionBorder(isSelected)
        }
        .buttonStyle(.plain)
    }
}
