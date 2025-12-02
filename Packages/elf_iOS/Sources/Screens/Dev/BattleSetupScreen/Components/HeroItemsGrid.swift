//
//  HeroItemsGrid.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 13.11.25.
//

import SwiftUI
import UIKit
import elf_Kit

// MARK: - HeroItemsGrid

struct HeroItemsGrid: View {

    // MARK: - Properties

    @Binding var selectedItems: [HeroItemType: UUID?]
    @Binding var armorValues: [BodyPart: Int16]
    let isSecondaryWeaponEnabled: Bool
    let twoHandedWeaponId: UUID?
    let onItemTap: (HeroItemType) -> Void

    // MARK: - Body

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
                shieldsSlot
            }
        }
    }

    // MARK: - Private Computed Properties

    @ViewBuilder
    private var shieldsSlot: some View {
        ZStack {
            // Check if two-handed weapon is equipped
            if let weaponId = twoHandedWeaponId {
                // Show two-handed weapon in shields slot with dark overlay
                Button(action: { handleItemTap(.shields) }) {
                    ZStack {
                        itemImage(uuid: weaponId, size: 30)
                        Color.black.opacity(0.4)
                            .allowsHitTesting(false)
                    }
                }
                .buttonStyle(ItemButtonStyle())
            } else {
                // Normal shields slot
                itemButton(for: .shields)
                if !isSecondaryWeaponEnabled {
                    Color.black.opacity(0.4)
                        .allowsHitTesting(false)
                }
            }
        }
    }

    // MARK: - Private Methods

    @ViewBuilder
    private func itemButton(for itemType: HeroItemType) -> some View {
        Button(action: { handleItemTap(itemType) }) {
            if let itemId = selectedItems[itemType], let uuid = itemId {
                // Show real item image
                itemImage(uuid: uuid, size: 30)
            } else {
                Color.clear
            }
        }
        .buttonStyle(ItemButtonStyle())
    }

    @ViewBuilder
    private func jewelryButton(for itemType: HeroItemType) -> some View {
        Button(action: { handleItemTap(itemType) }) {
            if let itemId = selectedItems[itemType], let uuid = itemId {
                // Show real jewelry image
                itemImage(uuid: uuid, size: 20)
            } else {
                Color.clear
            }
        }
        .buttonStyle(JewelryButtonStyle())
    }

    @ViewBuilder
    private func itemImage(uuid: UUID, size: CGFloat) -> some View {
        let imageName = uuid.uuidString.lowercased()

        if UIImage(named: imageName) != nil {
            // Real item image exists
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        } else {
            // Fallback placeholder for missing image
            Image(systemName: "photo.fill")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .foregroundColor(.gray.opacity(0.5))
        }
    }

    private func handleItemTap(_ itemType: HeroItemType) {
        onItemTap(itemType)
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
                    isSecondaryWeaponEnabled: true,
                    twoHandedWeaponId: nil,
                    onItemTap: { itemType in print("Preview tapped: \(itemType)") }
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
                    isSecondaryWeaponEnabled: false,
                    twoHandedWeaponId: nil,
                    onItemTap: { itemType in print("Preview tapped: \(itemType)") }
                )
            }
            .padding()
            .background(Color.black)
            .previewDisplayName("Secondary Disabled")
        }
        .previewLayout(.sizeThatFits)
    }
}
