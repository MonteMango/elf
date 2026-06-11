//
//  BuffCatalogID.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Stable UUIDs of catalog `Buff` entries that code needs to reference by name
/// (apply automatically, branch on presence, etc.). Keeping them here — beside
/// the `Buff` model — instead of inlining UUID literals at the use site means
/// renaming the constant catches every reader at compile time, and a typo in
/// the literal is caught at app startup by the `fatalError` below rather than
/// silently no-op'ing at runtime.
public enum BuffCatalogID {

    /// Battle-scoped Exhausted debuff auto-applied at end of a combat round
    /// when a combatant's EP reaches 0. Vanishes with the battle snapshot
    /// — never persists outside combat.
    public static let exhaustedBattle: BuffID = mustParse("BD000000-0000-4000-A000-000000000002")

    private static func mustParse(_ string: String) -> BuffID {
        guard let id = UUID(uuidString: string) else {
            fatalError("Invalid UUID literal in BuffCatalogID: \(string)")
        }
        return BuffID(rawValue: id)
    }
}
