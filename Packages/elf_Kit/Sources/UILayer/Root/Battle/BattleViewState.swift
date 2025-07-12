//
//  BattleViewState.swift
//  
//
//  Created by Vitalii Lytvynov on 20.09.24.
//

import Foundation

public enum BattleViewState: Equatable {
    case setup
    case selectItem(heroType: HeroType, heroItemType: HeroItemType, currentHeroItemId: UUID?)
    case fight
}
