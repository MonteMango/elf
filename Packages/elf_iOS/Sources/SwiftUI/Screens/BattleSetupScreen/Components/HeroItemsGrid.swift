//
//  HeroItemsGrid.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 13.11.25.
//

import SwiftUI
import elf_Kit

struct HeroItemsGrid: View {
    @Binding var selectedItems: [HeroItemType: Item?]
    @Binding var armorValues: [BodyPart: Int16]
    let isSecondaryWeaponEnabled: Bool

    var body: some View {
        HStack(alignment: .bottom, spacing: BattleSetupConstants.Spacing.itemGridSpacing) {
            // Left column
            VStack(spacing: 0) {
                itemButton(for: .helmet)
                itemButton(for: .gloves)
                itemButton(for: .shoes)
                itemButton(for: .weapons) // Primary weapon
            }

            // Center - Armor display and jewelry
            VStack(spacing: 0) {
                ArmorDisplay(armorValues: $armorValues)
                    .frame(minWidth: 100, minHeight: 180)

                Spacer()

                // Jewelry row
                HStack(spacing: 0) {
                    jewelryButton(for: .ring)
                    jewelryButton(for: .necklace)
                    jewelryButton(for: .earrings)
                }
            }

            // Right column
            VStack(spacing: 0) {
                itemButton(for: .upperBody)
                itemButton(for: .bottomBody)
                itemButton(for: .shirt)
                ZStack {
                    itemButton(for: .shields) // Secondary weapon
                    if !isSecondaryWeaponEnabled {
                        Color.black.opacity(0.4)
                            .allowsHitTesting(false)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func itemButton(for itemType: HeroItemType) -> some View {
        Button(action: { handleItemTap(itemType) }) {
            if let optionalItem = selectedItems[itemType], optionalItem != nil {
                Image(systemName: iconName(for: itemType))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.white)
            } else {
                Color.clear
            }
        }
        .buttonStyle(ItemButtonStyle())
    }

    @ViewBuilder
    private func jewelryButton(for itemType: HeroItemType) -> some View {
        Button(action: { handleItemTap(itemType) }) {
            if let optionalItem = selectedItems[itemType], optionalItem != nil {
                Image(systemName: iconName(for: itemType))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundColor(.white)
            } else {
                Color.clear
            }
        }
        .buttonStyle(JewelryButtonStyle())
    }

    private func handleItemTap(_ itemType: HeroItemType) {
        // Placeholder for item selection logic
        print("Item tapped: \(itemType)")
    }

    private func iconName(for itemType: HeroItemType) -> String {
        switch itemType {
        case .helmet:
            return "crown.fill"
        case .gloves:
            return "hand.raised.fill"
        case .shoes:
            return "shoe.fill"
        case .upperBody:
            return "tshirt.fill"
        case .bottomBody:
            return "figure.stand"
        case .shirt:
            return "rectangle.fill"
        case .ring:
            return "circle.fill"
        case .necklace:
            return "link.circle.fill"
        case .earrings:
            return "staroflife.fill"
        case .weapons:
            return "sword.fill"
        case .shields:
            return "shield.fill"
        }
    }
}

// MARK: - Preview

struct HeroItemsGrid_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VStack(spacing: 20) {
                Text("With All Items")
                    .foregroundColor(.white)
                    .font(.caption)
                HeroItemsGrid(
                    selectedItems: .constant([:]),
                    armorValues: .constant([
                        .head: 10,
                        .body: 15,
                        .legs: 12,
                        .leftHand: 8,
                        .rightHand: 8
                    ]),
                    isSecondaryWeaponEnabled: true
                )
            }
            .padding()
            .background(Color.black)
            .previewDisplayName("All Items")

            VStack(spacing: 20) {
                Text("Secondary Weapon Disabled")
                    .foregroundColor(.white)
                    .font(.caption)
                HeroItemsGrid(
                    selectedItems: .constant([:]),
                    armorValues: .constant([
                        .head: 5,
                        .body: 10,
                        .legs: 8,
                        .leftHand: 5,
                        .rightHand: 5
                    ]),
                    isSecondaryWeaponEnabled: false
                )
            }
            .padding()
            .background(Color.black)
            .previewDisplayName("Secondary Disabled")
        }
        .previewLayout(.sizeThatFits)
    }
}
