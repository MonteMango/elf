//
//  MaterialRef.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Type-safe reference to an inventory material's source catalog entry.
///
/// Replaces the former `(id: UUID, source: MaterialSource)` pair: a material is
/// always one of fish / herb / ore / monster-drop, each identified by its own
/// catalog id. Modelling it as a sum removes the `.rawValue` unwraps that used
/// to happen at every lookup site and makes the source/id pairing impossible to
/// get wrong.
public enum MaterialRef: Sendable, Hashable {
    case fish(FishID)
    case herb(HerbID)
    case ore(OreID)
    case monster(MaterialID)

    /// The underlying catalog id as a bare `UUID` (for cross-source identity
    /// checks, e.g. matching recipe ingredients that reference a raw id).
    public var rawValue: UUID {
        switch self {
        case .fish(let id): return id.rawValue
        case .herb(let id): return id.rawValue
        case .ore(let id): return id.rawValue
        case .monster(let id): return id.rawValue
        }
    }

    /// Which repository this material originates from.
    public var source: MaterialSource {
        switch self {
        case .fish: return .fish
        case .herb: return .herb
        case .ore: return .ore
        case .monster: return .monster
        }
    }

    /// Build from a raw id + source (boundary helper for recipe-ingredient and
    /// legacy-id call sites that don't yet carry a typed id).
    public init(id: UUID, source: MaterialSource) {
        switch source {
        case .fish: self = .fish(FishID(rawValue: id))
        case .herb: self = .herb(HerbID(rawValue: id))
        case .ore: self = .ore(OreID(rawValue: id))
        case .monster: self = .monster(MaterialID(rawValue: id))
        }
    }
}

// MARK: - Codable

extension MaterialRef: Codable {
    private enum CodingKeys: String, CodingKey {
        case source
        case id
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let source = try container.decode(MaterialSource.self, forKey: .source)
        let id = try container.decode(UUID.self, forKey: .id)
        self.init(id: id, source: source)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(source, forKey: .source)
        try container.encode(rawValue, forKey: .id)
    }
}
