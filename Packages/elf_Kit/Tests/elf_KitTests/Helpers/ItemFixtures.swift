//
//  ItemFixtures.swift
//  elf_KitTests
//
//  Created by Vitalii Lytvynov
//

import Foundation
@testable import elf_Kit

/// Shared JSON-backed factories for item types whose production initialisers
/// aren't publicly available (decoding from JSON is the only legitimate path).
///
/// Use these helpers from any test target file instead of redefining a local
/// `makeWeaponItem` / `makeShieldItem` — keeps required-field migrations
/// (e.g. `WeaponItem.epBlockCost` becoming non-optional) to a single edit.
enum TestFixtures {

    /// Build a `WeaponItem` via JSON decoding. Optional bonus fields (strength,
    /// agility, …) are omitted from the JSON when nil. `epBlockCost` is
    /// required by the model but defaults to 0 here so tests that don't care
    /// about EP can ignore it.
    static func weaponItem(
        id: UUID = UUID(),
        title: String = "Test Weapon",
        tier: Int16 = 1,
        handUse: WeaponHandUse,
        minimumAttackPoint: Int16 = 1,
        maximumAttackPoint: Int16 = 5,
        epBlockCost: Int16 = 0,
        strength: Int16? = nil,
        agility: Int16? = nil,
        power: Int16? = nil,
        instinct: Int16? = nil,
        endurance: Int16? = nil,
        hitPoints: Int16? = nil
    ) throws -> WeaponItem {
        var json: [String: Any] = [
            "id": id.uuidString,
            "title": title,
            "tier": tier,
            "minimumAttackPoint": minimumAttackPoint,
            "maximumAttackPoint": maximumAttackPoint,
            "handUse": handUse.rawValue,
            "epBlockCost": epBlockCost
        ]
        if let strength { json["strength"] = strength }
        if let agility { json["agility"] = agility }
        if let power { json["power"] = power }
        if let instinct { json["instinct"] = instinct }
        if let endurance { json["endurance"] = endurance }
        if let hitPoints { json["hitPoints"] = hitPoints }

        let data = try JSONSerialization.data(withJSONObject: json)
        return try JSONDecoder().decode(WeaponItem.self, from: data)
    }

    /// Build a `ShieldItem` via JSON decoding.
    static func shieldItem(
        id: UUID = UUID(),
        title: String = "Test Shield",
        tier: Int16 = 1,
        physicalDefensePoint: Int16 = 10
    ) throws -> ShieldItem {
        let json: [String: Any] = [
            "id": id.uuidString,
            "title": title,
            "tier": tier,
            "physicalDefensePoint": physicalDefensePoint
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        return try JSONDecoder().decode(ShieldItem.self, from: data)
    }
}
