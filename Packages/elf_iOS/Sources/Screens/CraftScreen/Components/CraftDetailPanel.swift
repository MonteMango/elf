//
//  CraftDetailPanel.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import elf_SwiftUI
import SwiftUI

struct CraftDetailPanel: View {
    let detail: CraftRecipeDetailDisplay?
    let onCraft: () -> Void

    var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        if let detail {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: ElfSpacing.large) {
                        // Item image + title
                        itemHeader(detail)

                        Divider()

                        // Attributes
                        attributesSection(detail.attributes)

                    }
                    .padding(ElfSpacing.xl)
                }

                // Materials + Craft button (fixed bottom)
                HStack(alignment: .bottom) {
                    materialsSection(detail)
                    Spacer()
                    VStack(alignment: .trailing, spacing: ElfSpacing.small) {
                        missingWarning(detail)
                        craftButton(canCraft: detail.canCraft)
                    }
                }
                .padding(ElfSpacing.xl)
            }
            .background {
                ElfColors.Background.card
            }
            .padding(.top, ElfSpacing.medium)
        } else {
            VStack {
                Spacer()
                Text("Select an item for craft")
                    .font(ElfFonts.Component.itemEmptyState)
                    .foregroundStyle(ElfColors.Text.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background { ElfColors.Background.card }
            .padding(.top, ElfSpacing.medium)
        }
    }

    // MARK: - Item Header

    @ViewBuilder
    private func itemHeader(_ detail: CraftRecipeDetailDisplay) -> some View {
        HStack(spacing: ElfSpacing.large) {
            Image(detail.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: ElfSizing.Craft.detailImageSize, height: ElfSizing.Craft.detailImageSize)

            VStack(alignment: .leading, spacing: ElfSpacing.xxs) {
                Text(detail.title)
                    .font(ElfFonts.Component.itemTitle)
                    .foregroundStyle(ElfColors.Text.primary)

                Text(detail.shortInfo)
                    .font(ElfFonts.Component.itemDetail)
                    .foregroundStyle(ElfColors.Text.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Attributes

    @ViewBuilder
    private func attributesSection(_ attrs: CraftItemAttributes) -> some View {
        VStack(alignment: .leading, spacing: ElfSpacing.xxs) {
            if attrs.strength > 0 { attributeRow("Strength", value: attrs.strength) }
            if attrs.agility > 0 { attributeRow("Agility", value: attrs.agility) }
            if attrs.power > 0 { attributeRow("Power", value: attrs.power) }
            if attrs.instinct > 0 { attributeRow("Instinct", value: attrs.instinct) }
            if attrs.endurance > 0 { attributeRow("Endurance", value: attrs.endurance) }
            if attrs.hitPoints > 0 { attributeRow("HP", value: attrs.hitPoints) }
            if attrs.manaPoints > 0 { attributeRow("MP", value: attrs.manaPoints) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func attributeRow(_ label: String, value: Int) -> some View {
        HStack {
            Text(label)
                .font(ElfFonts.Component.itemDetail)
                .foregroundStyle(ElfColors.Text.secondary)
            Spacer()
            Text("+\(value)")
                .font(ElfFonts.Component.statLabel)
                .foregroundStyle(ElfColors.Text.primary)
        }
    }

    // MARK: - Materials

    @ViewBuilder
    private func materialsSection(_ detail: CraftRecipeDetailDisplay) -> some View {
        VStack(alignment: .leading, spacing: ElfSpacing.xs) {
            Text("Required materials:")
                .font(ElfFonts.Component.statLabel)
                .foregroundStyle(ElfColors.Text.primary)

            ForEach(detail.ingredients) { ingredient in
                HStack(spacing: ElfSpacing.xs) {
                    Image(ingredient.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: ElfSizing.Icon.small, height: ElfSizing.Icon.small)

                    Text("x\(ingredient.required)")
                        .font(ElfFonts.Component.itemDetail)
                        .foregroundStyle(ingredient.isSufficient ? ElfColors.success : ElfColors.error)

                    Text("(\(ingredient.inBag))")
                        .font(ElfFonts.Component.itemDetail)
                        .foregroundStyle(ElfColors.Text.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Missing Warning

    @ViewBuilder
    private func missingWarning(_ detail: CraftRecipeDetailDisplay) -> some View {
        if !detail.missingIngredients.isEmpty {
            VStack(alignment: .trailing, spacing: ElfSpacing.xxxs) {
                ForEach(detail.missingIngredients, id: \.itemId) { missing in
                    let imageName = detail.ingredients.first { $0.id == missing.itemId }?.imageName
                    HStack(spacing: ElfSpacing.xxxs) {
                        Text("Need")
                        if let imageName {
                            Image(imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: ElfSizing.Craft.warningIconSize, height: ElfSizing.Craft.warningIconSize)
                        }
                        Text("×\(missing.deficit) more")
                    }
                    .font(ElfFonts.Component.dropItemName)
                    .foregroundStyle(ElfColors.Text.error)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    // MARK: - Craft Button

    private func craftButton(canCraft: Bool) -> some View {
        Button(action: onCraft) {
            Text("Craft")
        }
        .buttonStyle(.elfPrimary(isEnabled: canCraft))
        .disabled(!canCraft)
    }
}
