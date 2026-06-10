//
//  Item.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 10.11.24.
//

import Foundation

public protocol Item: Decodable, Sendable {
    var id: UUID { get }
    var title: String { get }
    var tier: Int16 { get }

    var isUnique: Bool? { get }

    var strength: Int16? { get }
    var agility: Int16? { get }
    var power: Int16? { get }
    var instinct: Int16? { get }
    var endurance: Int16? { get }

    var hitPoints: Int16? { get }
    var manaPoints: Int16? { get }
}

// MARK: - Attribute Bonuses

extension Item {
    var heroAttributes: HeroAttributes {
        HeroAttributes(
            hitPoints: Attribute(hitPoints ?? 0),
            manaPoints: Attribute(manaPoints ?? 0),
            agility: Attribute(agility ?? 0),
            strength: Attribute(strength ?? 0),
            power: Attribute(power ?? 0),
            instinct: Attribute(instinct ?? 0),
            endurance: Attribute(endurance ?? 0)
        )
    }
}
