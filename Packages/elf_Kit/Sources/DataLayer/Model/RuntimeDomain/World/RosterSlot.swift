//
//  RosterSlot.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 12.06.26.
//

import Foundation

/// Address of an elf within the roster: its house and member indices plus the
/// elf's `id`. Used by the world turn to read a bot on the main actor, hand a
/// value-type plan to the off-main simulator, and write the result back to the
/// exact same slot.
///
/// Indices are captured when the world-turn snapshot is built and applied
/// within the same main-actor frame, so they cannot drift; `id` is carried
/// alongside for verification and logging.
public struct RosterSlot: Sendable, Equatable, Hashable {
    public let houseIndex: Int
    public let memberIndex: Int
    public let id: ElfID

    public init(houseIndex: Int, memberIndex: Int, id: ElfID) {
        self.houseIndex = houseIndex
        self.memberIndex = memberIndex
        self.id = id
    }
}
