//
//  OreArea.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

public struct OreArea: Codable, Sendable {
    public let title: String
    public let ores: [OreID]

    public init(title: String, ores: [OreID]) {
        self.title = title
        self.ores = ores
    }
}
