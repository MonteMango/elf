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

    /// Global Exhausted debuff applied outside combat (e.g. activities). Has
    /// a multi-day expiry; persists across battles.
    public static let exhaustedGlobal: UUID = mustParse("BD000000-0000-4000-A000-000000000001")

    /// Battle-scoped Exhausted debuff auto-applied at end of a combat round
    /// when a combatant's EP reaches 0. Vanishes with the battle snapshot.
    /// Distinct from `exhaustedGlobal` so the runner can call
    /// `BuffApplicationService.applyAsBattle` without triggering the scope
    /// assertion (see `DefaultBuffApplicationService`).
    public static let exhaustedBattle: UUID = mustParse("BD000000-0000-4000-A000-000000000002")

    private static func mustParse(_ string: String) -> UUID {
        guard let id = UUID(uuidString: string) else {
            fatalError("Invalid UUID literal in BuffCatalogID: \(string)")
        }
        return id
    }
}
