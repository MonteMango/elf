//
//  VitalsRestore.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// How much of a squad member's reserves an event restores. A closed set so new
/// magnitudes are explicit; a `nil` `VitalsRestore?` means "no restore". Extend
/// with e.g. `case fraction(Double)` when an event needs partial healing.
public enum VitalsRestore: Sendable, Equatable {
    /// Restore HP/MP to full (living members only — no revive).
    case full
}
