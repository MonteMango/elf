//
//  InventoryScreenContent.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import SwiftUI

struct InventoryScreenContent: View {
    @State private var viewModel: InventoryViewModel
    let selectedItemId: UUID?

    init(viewModel: InventoryViewModel, selectedItemId: UUID? = nil) {
        self._viewModel = State(initialValue: viewModel)
        self.selectedItemId = selectedItemId
    }

    var body: some View {
        HStack(spacing: 0) {
            // Left panel: filters + grid + close button
            leftPanel
                .frame(maxWidth: .infinity)

            // Right panel: item details
            ItemDetailPanel(
                item: viewModel.selectedItem,
                onEquip: viewModel.equipSelectedItem,
                onUnequip: viewModel.unequipSelectedItem
            )
            .frame(width: 220)
        }
        .background {
            Color.white
        }
        .onAppear {
            viewModel.selectItemById(selectedItemId)
        }
        .onChange(of: selectedItemId) { _, newValue in
            viewModel.selectItemById(newValue)
        }
    }

    // MARK: - Left Panel

    private var leftPanel: some View {
        VStack(spacing: 10) {
            // Category buttons
            CategoryButtonsRow(
                selectedCategory: viewModel.selectedCategory,
                onCategoryTap: viewModel.selectCategory
            )

            // Subcategory buttons
            SubcategoryButtonsRow(
                titles: viewModel.currentSubcategoryTitles,
                selectedIndex: viewModel.selectedSubcategoryIndex,
                onSubcategoryTap: viewModel.selectSubcategory
            )

            // Inventory grid
            InventoryGrid(
                items: viewModel.filteredItems,
                selectedItemId: viewModel.selectedItemId,
                onItemTap: viewModel.selectItem
            )

            // Close button
            closeButton
        }
        .padding(.horizontal, 10)
    }

    // MARK: - Close Button

    private var closeButton: some View {
        Button(action: viewModel.closeInventory) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 14, weight: .bold))

                Text("Close inventory")
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background { Color.orange }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    InventoryScreenContent(
        viewModel: PreviewMockData.createMockInventoryViewModel()
    )
}
