//
//  FishArea.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 20.01.26.
//

import Foundation

public struct FishArea: Codable, Sendable {
    public let title: String
    public let fish: [FishID]

    public init(title: String, fish: [FishID]) {
        self.title = title
        self.fish = fish
    }
}
