//
//  DefaultHeroEquippedSlotResolver.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import Foundation
import UIKit

/// Default `HeroEquippedSlotResolver` implementation. Combines the domain
/// query (`EquipmentQueryService.equippedBaseItemIds`) with two UI-layer
/// concerns: asset-name resolution and the off-hand mirror for two-handed
/// weapons.
public struct DefaultHeroEquippedSlotResolver: HeroEquippedSlotResolver {

    private let equipmentQueryService: any EquipmentQueryService

    public init() {
        @Dependency(\.equipmentQueryService) var equipmentQueryService
        self.equipmentQueryService = equipmentQueryService
    }

    public func resolve(equipped: EquippedItems) -> [HeroItemType: HeroEquippedSlot] {
        let baseIds = equipmentQueryService.equippedBaseItemIds(from: equipped)
        var result: [HeroItemType: HeroEquippedSlot] = baseIds.mapValues { itemId in
            let candidateName = itemId.rawValue.uuidString.lowercased()
            let resolvedName = UIImage(named: candidateName) != nil ? candidateName : nil
            return HeroEquippedSlot(id: itemId.rawValue, imageName: resolvedName)
        }

        // Two-handed weapons occupy both hands but live in a single enum case,
        // so the off-hand slot is empty. Mirror the weapon icon there so the
        // user can see at a glance why the shield slot is unavailable.
        if case .twoHanded = equipped.weapons,
           let weaponSlot = result[.weapons] {
            result[.shields] = HeroEquippedSlot(
                id: weaponSlot.id,
                imageName: weaponSlot.imageName,
                mirroredFrom: .weapons
            )
        }
        return result
    }
}
