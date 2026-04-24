//
//  InventoryView.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import elf_SwiftUI
import SwiftUI

/// Inventory overlay embedded inside `GameDayScreen`. Not a navigation destination —
/// rendered inline, so it stays as a reusable view rather than a Screen.
struct InventoryView: View {
    @State private var viewModel: InventoryViewModel
    let selectedItemId: UUID?

    init(viewModel: InventoryViewModel, selectedItemId: UUID? = nil) {
        self._viewModel = State(initialValue: viewModel)
        self.selectedItemId = selectedItemId
    }

    var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        HStack(spacing: 0) {
            // Left panel: filters + grid + close button
            leftPanel
                .frame(maxWidth: .infinity)

            // Right panel: item details
            ItemDetailPanel(
                item: viewModel.selectedItem,
                onEquip: { viewModel.equipSelectedItem() },
                onUnequip: { viewModel.unequipSelectedItem() }
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
            CategoryButtonsRow(
                selectedCategory: viewModel.selectedCategory,
                onCategoryTap: viewModel.selectCategory
            )

            SubcategoryButtonsRow(
                titles: viewModel.currentSubcategoryTitles,
                selectedIndex: viewModel.selectedSubcategoryIndex,
                onSubcategoryTap: viewModel.selectSubcategory
            )

            InventoryGrid(
                items: viewModel.filteredItems,
                selectedItemId: viewModel.selectedItemId,
                onItemTap: viewModel.selectItem
            )

            closeButton
        }
        .padding(.horizontal, 10)
    }

    // MARK: - Close Button

    private var closeButton: some View {
        Button(action: viewModel.closeInventory) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.left")
                Text("Close inventory")
            }
            .font(ElfFonts.Component.closeButton)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background { Color.orange }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    InventoryView(
        viewModel: PreviewGame.createMockInventoryViewModel()
    )
}
#endif
