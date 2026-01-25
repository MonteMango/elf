//
//  MonsterCell.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 08.12.25.
//

import elf_Kit
import elf_SwiftUI
import SwiftUI

struct MonsterCell: View {
    let displayData: MonsterDisplayData

    var body: some View {
        VStack(spacing: ElfSpacing.small) {
            // Drop items row
            dropItemsRow

            // Monster image
            monsterImage

            // Monster name
            Text(displayData.title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(ElfColors.Text.primary)
        }
        .frame(width: 200)
    }

    // MARK: - Drop Items Row

    @ViewBuilder
    private var dropItemsRow: some View {
        HStack(spacing: ElfSpacing.small) {
            ForEach(displayData.drops) { drop in
                ItemCard(
                    imageName: drop.imageName,
                    rarityColor: .tier(drop.tier)
                )
            }
        }
    }

    // MARK: - Monster Image

    @ViewBuilder
    private var monsterImage: some View {
        if let uiImage = UIImage(named: displayData.imageName) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(
                    idealWidth: 150,
                    idealHeight: 150
                )
        } else {
            // Placeholder for missing image
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(
                    width: 150,
                    height: 150
                )
                .overlay(
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                )
        }
    }
}

#Preview {
    let mockDisplayData = MonsterDisplayData(
        id: UUID(),
        title: "Wolf",
        imageName: "monster_wolf",
        drops: [
            DropDisplayData(imageName: "sword_1", tier: 2),
            DropDisplayData(imageName: "material_monster_soul_gem", tier: 4)
        ]
    )

    MonsterCell(displayData: mockDisplayData)
        .padding()
        .background(Color.white)
}
