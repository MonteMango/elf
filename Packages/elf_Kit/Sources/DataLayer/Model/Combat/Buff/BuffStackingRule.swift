//
//  BuffStackingRule.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// How re-applying the same buff to an already-affected elf is handled.
/// - `.refresh`: keep one instance, reset its `appliedOnDay`.
/// - `.stack`: increment the existing instance's `stacks` (effects sum additively).
/// - `.ignore`: do nothing if already applied.
public enum BuffStackingRule: String, Codable, Sendable, Hashable {
    case refresh
    case stack
    case ignore
}
