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
    /// A healing spring. Drinking fully restores HP/MP of the living squad
    /// (downed members are not revived). Carries no payload — the effect is
    /// always a full restore.
    case healingSpring

    private enum DiscriminatorKey: String, CodingKey { case type }

    private enum Discriminator: String, Codable {
        case healingSpring
    }

    public init(from decoder: any Decoder) throws {
        let typeContainer = try decoder.container(keyedBy: DiscriminatorKey.self)
        let discriminator = try typeContainer.decode(Discriminator.self, forKey: .type)
        switch discriminator {
        case .healingSpring:
            self = .healingSpring
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var typeContainer = encoder.container(keyedBy: DiscriminatorKey.self)
        switch self {
        case .healingSpring:
            try typeContainer.encode(Discriminator.healingSpring, forKey: .type)
        }
    }
}
