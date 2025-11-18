//
//  HeroDisplayView.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 16.11.25.
//

import SwiftUI
import UIKit
import elf_Kit

// MARK: - HeroDisplayView

struct HeroDisplayView: View {

    // MARK: - Properties

    let hero: ElfHero
    let currentHP: Int
    let maxHP: Int
    let roundResults: [BodyPart: PointStatus]

    // MARK: - Body

    var body: some View {
        VStack(spacing: 10) {
            // HP Bar
            hpBar

            // Hero Image with overlays
            ZStack {
                // Layer 1: Hero image placeholder
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(
                        width: BattleFightConstants.Sizing.heroImageSize,
                        height: BattleFightConstants.Sizing.heroImageSize
                    )
                    .overlay(
                        Text("Hero")
                            .foregroundColor(.white.opacity(0.5))
                    )

                // Layer 2: Items Grid Overlay
                itemsGridOverlay

                // Layer 3: Result Dots Overlay (top layer)
                resultDotsOverlay
            }
        }
    }

    // MARK: - Private Views

    private var hpBar: some View {
        ZStack(alignment: .leading) {
            // Background
            RoundedRectangle(cornerRadius: BattleFightConstants.Sizing.hpBarCornerRadius)
                .fill(BattleFightConstants.Colors.hpBarBackground)

            // Fill
            RoundedRectangle(cornerRadius: BattleFightConstants.Sizing.hpBarCornerRadius)
                .fill(BattleFightConstants.Colors.hpBarFill)
                .frame(width: BattleFightConstants.Sizing.hpBarWidth * hpPercentage)

            // Text
            Text("\(currentHP)/\(maxHP)")
                .font(BattleFightConstants.Fonts.hpText)
                .foregroundColor(BattleFightConstants.Colors.hpBarText)
                .frame(width: BattleFightConstants.Sizing.hpBarWidth, alignment: .center)
        }
        .frame(width: BattleFightConstants.Sizing.hpBarWidth, height: BattleFightConstants.Sizing.hpBarHeight)
    }

    @ViewBuilder
    private var itemsGridOverlay: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let itemSize = BattleFightConstants.Sizing.battleItemSize
            let jewelrySize = BattleFightConstants.Sizing.battleJewelrySize
            let spacing: CGFloat = 4

            // Column positioning
            let leftColumnX: CGFloat = spacing
            let rightColumnX: CGFloat = width - itemSize - spacing

            ZStack {
                // LEFT column (4 items)
                VStack(spacing: spacing) {
                    itemSlot(item: hero.helmetElfItem)
                    itemSlot(item: hero.glovesElfItem)
                    itemSlot(item: hero.shoesElfItem)
                    itemSlot(item: hero.rightHandWeaponElfItem)
                }
                .position(x: leftColumnX + itemSize / 2, y: height / 2)

                // RIGHT column (4 items)
                VStack(spacing: spacing) {
                    itemSlot(item: hero.upperBodyElfItem ?? hero.robeElfItem)
                    itemSlot(item: hero.bottomBodyElfItem)
                    itemSlot(item: nil) // shirt placeholder
                    itemSlot(item: hero.shieldElfItem ?? hero.leftHandWeaponElfItem)
                }
                .position(x: rightColumnX + itemSize / 2, y: height / 2)

                // CENTER BOTTOM: Jewelry row (3 items)
                HStack(spacing: spacing) {
                    jewelrySlot(item: hero.ringElfItem)
                    jewelrySlot(item: hero.necklaceElfItem)
                    jewelrySlot(item: hero.earringsElfItem)
                }
                .position(x: width / 2, y: height - jewelrySize / 2 - spacing)
            }
        }
        .frame(
            width: BattleFightConstants.Sizing.heroImageSize,
            height: BattleFightConstants.Sizing.heroImageSize
        )
    }

    @ViewBuilder
    private func itemSlot(item: (any ElfItem)?) -> some View {
        ZStack {
            // Always show placeholder
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(
                    width: BattleFightConstants.Sizing.battleItemSize,
                    height: BattleFightConstants.Sizing.battleItemSize
                )

            // Item image if equipped
            if let elfItem = item {
                itemImage(id: elfItem.id, size: BattleFightConstants.Sizing.battleItemSize)
            }
        }
    }

    @ViewBuilder
    private func jewelrySlot(item: (any ElfItem)?) -> some View {
        ZStack {
            // Always show placeholder
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(
                    width: BattleFightConstants.Sizing.battleJewelrySize,
                    height: BattleFightConstants.Sizing.battleJewelrySize
                )

            // Item image if equipped
            if let elfItem = item {
                itemImage(id: elfItem.id, size: BattleFightConstants.Sizing.battleJewelrySize)
            }
        }
    }

    @ViewBuilder
    private func itemImage(id: UUID, size: CGFloat) -> some View {
        let imageName = id.uuidString.lowercased()

        if UIImage(named: imageName) != nil {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        } else {
            Image(systemName: "photo.fill")
                .resizable()
                .scaledToFit()
                .frame(width: size * 0.6, height: size * 0.6)
                .foregroundColor(.gray.opacity(0.5))
        }
    }

    @ViewBuilder
    private var resultDotsOverlay: some View {
        GeometryReader { geometry in
            let centerX = geometry.size.width / 2
            let centerY = geometry.size.height / 2
            let offset: CGFloat = 30

            ZStack {
                // Top - Head
                if let status = roundResults[.head] {
                    resultLabel(status: status)
                        .position(x: centerX, y: centerY - offset)
                }

                // Center - Body
                if let status = roundResults[.body] {
                    resultLabel(status: status)
                        .position(x: centerX, y: centerY)
                }

                // Left - Left Hand
                if let status = roundResults[.leftHand] {
                    resultLabel(status: status)
                        .position(x: centerX - offset, y: centerY)
                }

                // Right - Right Hand
                if let status = roundResults[.rightHand] {
                    resultLabel(status: status)
                        .position(x: centerX + offset, y: centerY)
                }

                // Bottom - Legs
                if let status = roundResults[.legs] {
                    resultLabel(status: status)
                        .position(x: centerX, y: centerY + offset)
                }
            }
        }
        .frame(
            width: BattleFightConstants.Sizing.heroImageSize,
            height: BattleFightConstants.Sizing.heroImageSize
        )
    }

    @ViewBuilder
    private func resultLabel(status: PointStatus) -> some View {
        if let text = statusText(for: status) {
            Text(text)
                .font(BattleFightConstants.Fonts.resultStatusText)
                .foregroundColor(statusColor(for: status))
        }
    }

    private func statusText(for status: PointStatus) -> String? {
        switch status {
        case .dodged:
            return "dodge"
        case .hit(let damage):
            return "\(damage)"
        case .critHit(let damage):
            return "crit \(damage)"
        case .blocked:
            return "block"
        case .nothing:
            return nil
        }
    }

    private func statusColor(for status: PointStatus) -> Color {
        switch status {
        case .dodged:
            return .green
        case .hit:
            return .white
        case .critHit:
            return .red
        case .blocked:
            return .blue
        case .nothing:
            return .clear
        }
    }

    // MARK: - Computed Properties

    private var hpPercentage: CGFloat {
        guard maxHP > 0 else { return 0 }
        return CGFloat(currentHP) / CGFloat(maxHP)
    }
}

// MARK: - Preview

// Mock Item classes for preview
fileprivate final class MockDefenseItem: Item {
    let id = UUID()
    let title = "Mock Item"
    let tier: Int16 = 1
    let isUnique: Bool? = false
    let strength: Int16? = 5
    let agility: Int16? = 5
    let power: Int16? = 5
    let instinct: Int16? = 5
    let hitPoints: Int16? = 10
    let manaPoints: Int16? = 10

    enum CodingKeys: CodingKey {}
}

fileprivate final class MockWeaponItem: Item {
    let id = UUID()
    let title = "Mock Weapon"
    let tier: Int16 = 1
    let isUnique: Bool? = false
    let strength: Int16? = 10
    let agility: Int16? = 5
    let power: Int16? = 5
    let instinct: Int16? = 5
    let hitPoints: Int16? = 0
    let manaPoints: Int16? = 0

    enum CodingKeys: CodingKey {}
}

struct HeroDisplayView_Previews: PreviewProvider {
    static var previews: some View {
        // Preview 1: Hero without items
        let mockHeroNoItems = ElfHero(
            level: 10,
            fightStyleAttributes: HeroAttributes(
                hitPoints: 100,
                manaPoints: 50,
                agility: 10,
                strength: 15,
                power: 12,
                instinct: 8
            ),
            randomLevelAttributes: HeroAttributes(
                hitPoints: 50,
                manaPoints: 25,
                agility: 5,
                strength: 7,
                power: 6,
                instinct: 4
            ),
            helmetElfItem: nil,
            glovesElfItem: nil,
            shoesElfItem: nil,
            upperBodyElfItem: nil,
            bottomBodyElfItem: nil,
            robeElfItem: nil,
            leftHandWeaponElfItem: nil,
            rightHandWeaponElfItem: nil,
            shieldElfItem: nil,
            ringElfItem: nil,
            necklaceElfItem: nil,
            earringsElfItem: nil
        )

        // Preview 2: Simulate hero with some equipped items
        // Note: Creating real Item instances requires decoder, so we'll create a mock ElfDefenseItem
        let mockDefenseItem = ElfDefenseItem(
            id: UUID(),
            item: MockDefenseItem()
        )

        let mockWeaponItem = ElfWeaponItem(
            id: UUID(),
            item: MockWeaponItem(),
            enchantLevel: 0
        )

        let mockHeroWithItems = ElfHero(
            level: 15,
            fightStyleAttributes: HeroAttributes(
                hitPoints: 150,
                manaPoints: 60,
                agility: 12,
                strength: 18,
                power: 14,
                instinct: 10
            ),
            randomLevelAttributes: HeroAttributes(
                hitPoints: 75,
                manaPoints: 30,
                agility: 6,
                strength: 9,
                power: 7,
                instinct: 5
            ),
            helmetElfItem: mockDefenseItem,
            glovesElfItem: mockDefenseItem,
            shoesElfItem: mockDefenseItem,
            upperBodyElfItem: mockDefenseItem,
            bottomBodyElfItem: mockDefenseItem,
            robeElfItem: nil,
            leftHandWeaponElfItem: nil,
            rightHandWeaponElfItem: mockWeaponItem,
            shieldElfItem: nil,
            ringElfItem: nil,
            necklaceElfItem: nil,
            earringsElfItem: nil
        )

        HStack(spacing: 30) {
            HeroDisplayView(
                hero: mockHeroNoItems,
                currentHP: 120,
                maxHP: 150,
                roundResults: [
                    .head: .blocked,
                    .body: .hit(damage: 10),
                    .leftHand: .nothing,
                    .rightHand: .critHit(damage: 20),
                    .legs: .dodged
                ]
            )
            .frame(width: 150)
            .previewDisplayName("Hero Display - No Items")

            HeroDisplayView(
                hero: mockHeroWithItems,
                currentHP: 180,
                maxHP: 225,
                roundResults: [
                    .head: .hit(damage: 5),
                    .body: .blocked,
                    .leftHand: .dodged,
                    .rightHand: .critHit(damage: 25),
                    .legs: .nothing
                ]
            )
            .frame(width: 150)
            .previewDisplayName("Hero Display - With Items")
        }
        .padding()
        .background(Color.black)
        .previewLayout(.sizeThatFits)
    }
}
