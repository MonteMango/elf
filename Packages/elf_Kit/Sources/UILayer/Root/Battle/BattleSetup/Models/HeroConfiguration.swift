//
//  HeroConfiguration.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 31.10.24.
//

import Combine
import Foundation

public final class HeroConfiguration: ObservableObject {
    
    @Published public var level: Int16 = 1
    
    @Published public var fightStyle: FightStyle? = nil
    
    @Published public var fightStyleAttributes: HeroAttributes? = nil
    @Published public var levelRandomAttributes: [Int16: HeroAttributes]? = nil
    @Published public var itemsAttributes: HeroAttributes? = nil
    
    // Используем словарь для хранения идентификаторов предметов экипировки
    @Published public var itemIds: [HeroItemType: UUID?] = [
        .helmet: nil,
        .gloves: nil,
        .shoes: nil,
        .upperBody: nil,
        .bottomBody: nil,
        .shirt: nil,
        .ring: nil,
        .necklace: nil,
        .earrings: nil,
        .weapons: nil
    ]
}
