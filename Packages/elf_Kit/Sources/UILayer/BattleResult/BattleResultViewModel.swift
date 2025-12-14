//
//  BattleResultViewModel.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 12.12.25.
//

import Foundation

@Observable
@MainActor
public final class BattleResultViewModel {

    // MARK: - Properties

    public let result: ManualBattleResult

    // MARK: - Initialization

    public init(result: ManualBattleResult) {
        self.result = result
    }
}
