//
//  HeroItems.swift
//
//
//  Created by Vitalii Lytvynov on 21.09.24.
//

import Foundation

public struct HeroItems: Decodable {
    public let version: String
    
    public let helmets: [DefenseItem]
    public let gloves: [DefenseItem]
    public let shoes: [DefenseItem]
    
    public let upperBodies: [DefenseItem]
    public let bottomBodies: [DefenseItem]
    public let robes: [RobeItem]
    
    public let primaryWeapons: [OffenseItem]
    public let secondaryWeapons: [OffenseItem]
    public let shields: [ShieldItem]
    
    public let rings: [JewelryItem]
    public let necklaces: [JewelryItem]
    public let earrings: [JewelryItem]
}

public protocol Item: Decodable {
    var id: UUID { get }
    var title: String { get }
    var tier: Int16 { get }
}

public struct DefenseItem: Item {
    public let id: UUID
    public let title: String
    public let tier: Int16
    
    public let physicalDefensePoint: Int16
    public let protectParts: [ProtectBodyPart]
}

public struct RobeItem: Item {
    public let id: UUID
    public let title: String
    public let tier: Int16
}

public struct JewelryItem: Item {
    public let id: UUID
    public let title: String
    public let tier: Int16
    
    public let magicalDefensePoint: Int16
}

public struct OffenseItem: Item {
    public let id: UUID
    public let title: String
    public let tier: Int16
    
    public let minimumAttackPoint: Int16
    public let maximumAttackPoint: Int16
    
    public let handUse: WeaponHandUse
}

public struct ShieldItem: Item {
    public let id: UUID
    public let title: String
    public let tier: Int16
    
    public let physicalDefensePoint: Int16
}

public enum ProtectBodyPart: String, Decodable {
    case head
    case body
    case leftHand
    case rightHand
    case legs
}

public enum WeaponHandUse: String, Decodable {
    case primary
    case primaryOrSecondary
    case both
}
