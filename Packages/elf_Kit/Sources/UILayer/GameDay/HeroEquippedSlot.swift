//
//  HeroEquippedSlot.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Display DTO describing one equipped slot on `HeroSection`.
///
/// `imageName` is the asset name resolved by the ViewModel — `nil` means no
/// matching asset exists in the catalog and the view should render a placeholder.
/// Resolution happens once per equip event in the data layer, not on every body render.
public struct HeroEquippedSlot: Equatable, Sendable {
    public let id: UUID
    public let imageName: String?

    public init(id: UUID, imageName: String?) {
        self.id = id
        self.imageName = imageName
    }
}
