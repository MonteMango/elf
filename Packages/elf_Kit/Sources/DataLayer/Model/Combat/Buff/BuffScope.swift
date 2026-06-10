//
//  BuffScope.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Where the buff lives. `.global` persists on the elf across battles; `.battle`
/// exists only inside one `Battle` and is discarded with the snapshot.
public enum BuffScope: String, Codable, Sendable, Hashable {
    case battle
    case global
}
