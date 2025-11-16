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

    public var battle: Battle
    public var battleEnded: Bool = false

    // MARK: - Initialization

    public init(battle: Battle) {
        self.battle = battle
    }

    // MARK: - Actions

    public func finishBattle() {
        // When battle logic is implemented, call this to trigger navigation
        battleEnded = true
    }
}
