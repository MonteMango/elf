//
//  MonsterCell.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 08.12.25.
//

import elf_Kit
import SwiftUI

struct MonsterCell: View {
    let displayData: MonsterDisplayData

    var body: some View {
        VStack(spacing: HuntConstants.Spacing.componentSpacing) {
            // Drop items row
            dropItemsRow

            // Monster image
            monsterImage

            // Monster name
            Text(displayData.title)
                .font(HuntConstants.Fonts.monsterName)
                .foregroundColor(HuntConstants.Colors.monsterNameText)
        }
        .frame(width: HuntConstants.Sizing.monsterCellWidth)
    }

    // MARK: - Drop Items Row

    @ViewBuilder
    private var dropItemsRow: some View {
        HStack(spacing: HuntConstants.Spacing.dropItemSpacing) {
            ForEach(displayData.dropImageNames, id: \.self) { imageName in
                dropItemView(imageName: imageName)
            }
        }
    }

    @ViewBuilder
    private func dropItemView(imageName: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: HuntConstants.Sizing.dropItemCornerRadius)
                .fill(HuntConstants.Colors.dropItemBackground)

            RoundedRectangle(cornerRadius: HuntConstants.Sizing.dropItemCornerRadius)
                .stroke(HuntConstants.Colors.dropItemBorder, lineWidth: HuntConstants.Sizing.dropItemBorderWidth)

            // Try to load image, fallback to placeholder
            if let uiImage = UIImage(named: imageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .padding(4)
            } else {
                Image(systemName: "gift.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.orange)
            }
        }
        .frame(
            width: HuntConstants.Sizing.dropItemSize,
            height: HuntConstants.Sizing.dropItemSize
        )
    }

    // MARK: - Monster Image

    @ViewBuilder
    private var monsterImage: some View {
        if let uiImage = UIImage(named: displayData.imageName) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(
                    idealWidth: HuntConstants.Sizing.monsterImageSize,
                    idealHeight: HuntConstants.Sizing.monsterImageSize
                )
        } else {
            // Placeholder for missing image
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(
                    width: HuntConstants.Sizing.monsterImageSize,
                    height: HuntConstants.Sizing.monsterImageSize
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
        dropImageNames: ["sword_1", "material_monster_soul_gem"]
    )

    MonsterCell(displayData: mockDisplayData)
        .padding()
        .background(Color.white)
}
