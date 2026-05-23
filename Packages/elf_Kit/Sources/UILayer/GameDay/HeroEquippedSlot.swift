//
//  HeroEquippedSlot.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Display DTO describing one equipped slot on `HeroSection`.
///
/// `imageName` is the asset name resolved by the ViewModel before being passed
/// to the view; `nil` means no matching asset exists in the catalog and the
/// view should render a placeholder.
///
/// `mirroredFrom` is non-nil when this slot does not own its own item but
/// visually reflects an item that lives in another slot (e.g. the off-hand
/// slot reflecting a two-handed weapon equipped in the weapons slot). The
/// view renders mirrored slots with reduced opacity and routes interactions
/// to the source slot type.
public struct HeroEquippedSlot: Hashable, Sendable {
    public let id: UUID
    public let imageName: String?
    public let mirroredFrom: HeroItemType?

    public var isMirror: Bool { mirroredFrom != nil }

    public init(id: UUID, imageName: String?, mirroredFrom: HeroItemType? = nil) {
        self.id = id
        self.imageName = imageName
        self.mirroredFrom = mirroredFrom
    }
}
