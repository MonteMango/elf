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
    
    var hitPoints: Int16? { get }
    var manaPoints: Int16? { get }
}
