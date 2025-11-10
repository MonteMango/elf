//
//  BattleViewState.swift
//  
//
//  Created by Vitalii Lytvynov on 20.09.24.
//

import Foundation

public enum BattleViewState {
    case setup
    case selectItem(heroType: HeroType, heroItemType: HeroItemType, currentHeroItemId: UUID?)
    case fight(user: HeroConfiguration, enemy: HeroConfiguration)
}

extension BattleViewState: Equatable {
    public static func == (lhs: BattleViewState, rhs: BattleViewState) -> Bool {
        switch (lhs, rhs) {
        case (.setup, .setup):
            return true
        case let (.selectItem(lHero, lItem, lId), .selectItem(rHero, rItem, rId)):
            return lHero == rHero && lItem == rItem && lId == rId
        case (.fight, .fight):
            return false
        default:
            return false
        }
    }
}
