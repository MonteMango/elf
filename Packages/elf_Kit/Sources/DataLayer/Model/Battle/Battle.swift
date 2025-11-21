//
//  Battle.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 15.08.25.
//

import Foundation

public struct Battle: Sendable, Identifiable {
    public let id: UUID

    // when battle starts there are 2 teams. The values passed as struct and never changed. These are initial information about ElfHero
    public let leftTeam: [ElfHero]
    public let rightTeam: [ElfHero]

    public var currentRound: Int {
        // based on roundLog.count + 1
        return roundLog.count + 1
    }

    // history of rounds
    public var roundLog: [ManualBattleRoundLog] = []

    public init(id: UUID = UUID(), leftTeam: [ElfHero], rightTeam: [ElfHero]) {
        self.id = id
        self.leftTeam = leftTeam
        self.rightTeam = rightTeam
    }
}
