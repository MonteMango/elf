//
//  EquipmentSlotView.swift
//  elf_SwiftUI
//
//  Created by Vitalii Lytvynov
//

import SwiftUI

/// One equipment slot cell, domain-agnostic. Renders the slot background, an
/// optional border, and (when an item is present) an icon. Mirrored items —
/// the off-hand reflection of a two-handed weapon, for example — are drawn at
/// reduced opacity.
///
/// Callers pre-resolve the asset name and the mirror flag; this view stays a
/// pure rendering primitive shared by `HeroSection` (Game Day), `SquadElfCell`
/// (Dungeon → Squad) and `CombatantBodyView` (Battle Fight).
public struct EquipmentSlotView: View {

    public struct ItemContent: Equatable, Sendable {
        public let imageName: String?
        public let isMirror: Bool

        public init(imageName: String?, isMirror: Bool = false) {
            self.imageName = imageName
            self.isMirror = isMirror
        }
    }

    // MARK: - Properties

    let item: ItemContent?
    let slotSize: CGFloat
    let iconSize: CGFloat
    let showBorder: Bool
    let placeholderScale: CGFloat

    // MARK: - Init

    public init(
        item: ItemContent?,
        slotSize: CGFloat,
        iconSize: CGFloat? = nil,
        showBorder: Bool = true,
        placeholderScale: CGFloat = 1.0
    ) {
        self.item = item
        self.slotSize = slotSize
        self.iconSize = iconSize ?? slotSize
        self.showBorder = showBorder
        self.placeholderScale = placeholderScale
    }

    // MARK: - Body

    public var body: some View {
        Rectangle()
            .fill(ElfColors.Interactive.slotBackground)
            .frame(width: slotSize, height: slotSize)
            .overlay {
                if showBorder {
                    Rectangle()
                        .stroke(ElfColors.Interactive.border, lineWidth: 1)
                }
            }
            .overlay {
                if let item {
                    ItemIconImage(
                        imageName: item.imageName,
                        size: iconSize,
                        placeholderScale: placeholderScale,
                        opacity: item.isMirror ? ElfOpacity.GameDay.mirroredSlot : 1.0
                    )
                }
            }
            .contentShape(Rectangle())
    }
}

#if DEBUG
#Preview {
    HStack(spacing: 16) {
        EquipmentSlotView(item: nil, slotSize: 40, iconSize: 32)
        EquipmentSlotView(item: .init(imageName: nil), slotSize: 40, iconSize: 32)
        EquipmentSlotView(item: .init(imageName: nil, isMirror: true), slotSize: 40, iconSize: 32)
        EquipmentSlotView(item: .init(imageName: nil), slotSize: 30, iconSize: 22)
        EquipmentSlotView(item: .init(imageName: nil), slotSize: 40, showBorder: false, placeholderScale: 0.6)
    }
    .padding()
    .background(Color.white)
}
#endif
