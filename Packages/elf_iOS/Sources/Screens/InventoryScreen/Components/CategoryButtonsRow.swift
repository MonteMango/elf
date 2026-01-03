//
//  CategoryButtonsRow.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import SwiftUI

struct CategoryButtonsRow: View {
    let selectedCategory: InventoryCategory
    let onCategoryTap: (InventoryCategory) -> Void

    private let buttonSize: CGFloat = 50

    var body: some View {
        HStack(spacing: 10) {
            ForEach(InventoryCategory.allCases, id: \.self) { category in
                CategoryButton(
                    title: category.displayTitle,
                    isSelected: category == selectedCategory,
                    size: buttonSize,
                    onTap: { onCategoryTap(category) }
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Category Button

private struct CategoryButton: View {
    let title: String
    let isSelected: Bool
    let size: CGFloat
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(isSelected ? Color.orange : Color.white)

                Text(title)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(isSelected ? .white : .orange)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(5)
            }
            .frame(width: size, height: size)
            .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 20) {
        CategoryButtonsRow(
            selectedCategory: .weapons,
            onCategoryTap: { _ in }
        )

        CategoryButtonsRow(
            selectedCategory: .armor,
            onCategoryTap: { _ in }
        )
    }
    .padding()
    .background(Color.white)
}
