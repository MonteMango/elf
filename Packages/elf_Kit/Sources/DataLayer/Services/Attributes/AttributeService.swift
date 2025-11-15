//
//  AttributeService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 01.11.24.
//

import Foundation

public protocol AttributeService: Sendable {
    
    func getAllFightStyleAttributes(for fightStyle: FightStyle, at level: Int16) async -> HeroAttributes
    
    func getRandomLevelAttributes() async -> HeroAttributes
    func getAllRandomLevelAttributes(for level: Int16) async -> HeroAttributes
    
    func getAllItemsAttrbutes(for itemIds: [UUID]) async -> HeroAttributes
}
