//
//  OffenseItem.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 10.11.24.
//

import Foundation

public struct OffenseItem: Item {
    public let id: UUID
    public let title: String
    public let tier: Int16
    
    public let minimumAttackPoint: Int16
    public let maximumAttackPoint: Int16
    
    public let handUse: WeaponHandUse
}
