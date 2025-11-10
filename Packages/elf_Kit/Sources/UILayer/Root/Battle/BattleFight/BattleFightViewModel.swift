//
//  BattleFightViewModel.swift
//
//
//  Created by Vitalii Lytvynov on 28.08.24.
//

import Foundation

public final class BattleFightViewModel {
    
    private let battleViewStateDelegate: AnyViewStateDelegate<BattleViewState>
    
    public init(
        userHeroConfiguration: HeroConfiguration,
        enemyHeroConfiguration: HeroConfiguration,
        battleViewStateDelegate: AnyViewStateDelegate<BattleViewState>) {
        self.battleViewStateDelegate = battleViewStateDelegate
    }
    
    @objc
    public func closeButtonAction() {
        battleViewStateDelegate.setViewState(.setup)
    }
}
