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
