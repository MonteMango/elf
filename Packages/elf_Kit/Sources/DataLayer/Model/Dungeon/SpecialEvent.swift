//
//  SpecialEvent.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Closed set of non-combat dungeon events. Add a new case to extend.
/// JSON shape: `{ "type": "<case>", ...payload }`.
public enum SpecialEvent: Codable, Sendable, Equatable, Hashable {
    case healingSpring(healPercent: Int)

    private enum DiscriminatorKey: String, CodingKey { case type }

    private enum HealingSpringKey: String, CodingKey { case healPercent }

    private enum Discriminator: String, Codable {
        case healingSpring
    }

    public init(from decoder: any Decoder) throws {
        let typeContainer = try decoder.container(keyedBy: DiscriminatorKey.self)
        let discriminator = try typeContainer.decode(Discriminator.self, forKey: .type)
        switch discriminator {
        case .healingSpring:
            let payload = try decoder.container(keyedBy: HealingSpringKey.self)
            let healPercent = try payload.decode(Int.self, forKey: .healPercent)
            self = .healingSpring(healPercent: healPercent)
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var typeContainer = encoder.container(keyedBy: DiscriminatorKey.self)
        switch self {
        case .healingSpring(let healPercent):
            try typeContainer.encode(Discriminator.healingSpring, forKey: .type)
            var payload = encoder.container(keyedBy: HealingSpringKey.self)
            try payload.encode(healPercent, forKey: .healPercent)
        }
    }
}
