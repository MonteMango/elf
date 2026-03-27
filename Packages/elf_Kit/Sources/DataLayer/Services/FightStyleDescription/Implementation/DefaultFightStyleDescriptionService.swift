//
//  DefaultFightStyleDescriptionService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 26.11.25.
//

import Foundation

/// Default implementation of FightStyleDescriptionService
public struct DefaultFightStyleDescriptionService: FightStyleDescriptionService {

    public init() {}

    public func getDescription(for style: FightStyle) async -> String {
        switch style {
        case .dodge:
            return "Your fight tactic is based on dodging enemy attacks. You exhaust your enemies by avoiding their strikes. You deal small periodic damage over time, but you are weak against enemy attacks."
        case .crit:
            return "Your fight tactic is based on dealing high damage. You are able to break through enemy blocks, but you are weak against enemy attacks."
        case .def:
            return "You prefer honest combat without any tricks. Your victory depends on strength and endurance."
        }
    }

    public func getAttributeBonusDescription(for style: FightStyle) async -> String {
        switch style {
        case .dodge:
            return "Agility +4, Instinct +1, Strength +1"
        case .crit:
            return "Power +4, Instinct +1, Strength +1"
        case .def:
            return "Strength +2, Instinct +2, HP + 2"
        }
    }
}
