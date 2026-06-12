//
//  BotTurnContext.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 12.06.26.
//

import Foundation

/// Input to the world turn for a single AI elf: where it lives (`slot`) and a
/// value-type copy of its current state (`elf`). The `GameDayStateViewModel`
/// builds these on the main actor from the roster, then hands the array to
/// `WorldTurnRunner`, which simulates them off-main. The `elf` copy is the
/// isolation barrier — the simulation never touches the observable `GameStore`.
public struct BotTurnContext: Sendable, Equatable {
    public let slot: RosterSlot
    public let elf: ElfInfo

    public init(slot: RosterSlot, elf: ElfInfo) {
        self.slot = slot
        self.elf = elf
    }
}
