//
//  BattleFightViewModel.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 12.11.25.
//

import Foundation

@Observable
public final class BattleFightViewModel {

    // MARK: - State

    public let userHeroConfiguration: HeroConfiguration
    public let enemyHeroConfiguration: HeroConfiguration
    public var battleEnded: Bool = false

    // MARK: - Initialization

    public init(
        userHeroConfiguration: HeroConfiguration,
        enemyHeroConfiguration: HeroConfiguration
    ) {
        self.userHeroConfiguration = userHeroConfiguration
        self.enemyHeroConfiguration = enemyHeroConfiguration
    }

    // MARK: - Actions

    public func finishBattle() {
        // When battle logic is implemented, call this to trigger navigation
        battleEnded = true
    }
}
