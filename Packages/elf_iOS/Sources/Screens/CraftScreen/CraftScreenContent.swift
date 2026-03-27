//
//  CraftScreenContent.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import elf_SwiftUI
import SwiftUI

struct CraftScreenContent: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel: CraftViewModel

    init(viewModel: CraftViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        HStack(spacing: 0) {
            // Left panel: back + filters + recipe list
            leftPanel
                .frame(maxWidth: .infinity)

            // Right panel: recipe detail + craft button
            CraftDetailPanel(
                detail: viewModel.selectedRecipeDetail,
                onCraft: { Task { await viewModel.craft() } }
            )
            .frame(width: ElfSizing.Craft.detailPanelWidth)
        }
        .background(ElfColors.Background.primary)
        .task { await viewModel.refreshRecipes() }
        .overlay {
            if viewModel.isCrafting {
                ZStack {
                    ElfColors.Background.overlayMedium.ignoresSafeArea()

                    VStack(spacing: ElfSpacing.section) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(ElfColors.primary)

                        Text("Crafting...")
                            .font(ElfFonts.Component.sectionTitle)
                            .foregroundStyle(ElfColors.Text.primary)
                    }
                    .frame(width: ElfSizing.FishingProgress.width, height: ElfSizing.FishingProgress.height)
                    .background(ElfColors.Background.primary)
                    .clipShape(RoundedRectangle(cornerRadius: ElfCornerRadius.card))
                    .elfShadow(ElfShadows.medium)
                }
            }
        }
    }

    // MARK: - Left Panel

    private var leftPanel: some View {
        VStack(spacing: ElfSpacing.medium) {
            // Back button + category filters
            ZStack {
                CraftCategoryButtonsRow(
                    selectedCategory: viewModel.selectedCategory,
                    onCategoryTap: viewModel.selectCategory
                )

                HStack {
                    BackButton(action: { router.pop() })
                    Spacer()
                }
            }

            // Recipe list
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: ElfSpacing.xl) {
                    ForEach(viewModel.filteredRecipes) { recipe in
                        CraftRecipeCell(
                            item: recipe,
                            isSelected: recipe.id == viewModel.selectedRecipeId,
                            onTap: { viewModel.selectRecipe(recipe.id) }
                        )
                    }
                }
                .padding(.vertical, ElfSpacing.component)
            }
        }
        .padding(.horizontal, ElfSpacing.medium)
        .padding(.top, ElfSpacing.medium)
    }

}
