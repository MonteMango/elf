//
//  BuffsData.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Top-level decoded shape of `Buffs.json`.
public struct BuffsData: Codable, Sendable {

    public let version: String
    public let buffs: [Buff]

    public init(version: String, buffs: [Buff]) {
        self.version = version
        self.buffs = buffs
    }
}
