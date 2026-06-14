//
//  DefaultSpecialEventResolver.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Default `SpecialEventResolver`: encodes the rules for each dungeon event.
public struct DefaultSpecialEventResolver: SpecialEventResolver {

    public init() {}

    public func resolve(_ event: SpecialEvent) -> DungeonEventOutcome {
        switch event {
        case .healingSpring:
            // Drinking fully restores the living squad and clears the room.
            return DungeonEventOutcome(restore: .full, clearsRoom: true)
        }
    }
}
