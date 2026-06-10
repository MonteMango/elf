//
//  HeroItems.swift
//
//
//  Created by Vitalii Lytvynov on 21.09.24.
//

import Foundation

public struct HeroItems: Decodable, Sendable {
    public let version: String

    public let helmets: [DefenseItem]
    public let gloves: [DefenseItem]
    public let shoes: [DefenseItem]

    public let upperBodies: [DefenseItem]
    public let bottomBodies: [DefenseItem]
    public let robes: [RobeItem]

    public let weapons: [WeaponItem]
    public let shields: [ShieldItem]

    public let rings: [JewelryItem]
    public let necklaces: [JewelryItem]
    public let earrings: [JewelryItem]

    public static let empty = HeroItems(
        version: "1.0-empty",
        helmets: [], gloves: [], shoes: [],
        upperBodies: [], bottomBodies: [], robes: [],
        weapons: [], shields: [],
        rings: [], necklaces: [], earrings: []
    )
}
