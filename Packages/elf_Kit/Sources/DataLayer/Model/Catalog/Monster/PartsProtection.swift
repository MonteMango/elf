//
//  PartsProtection.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 07.12.24.
//

import Foundation

public struct PartsProtection: Codable, Sendable, Hashable {
    public let head: Int
    public let left: Int
    public let center: Int
    public let right: Int
    public let legs: Int

    public init(head: Int, left: Int, center: Int, right: Int, legs: Int) {
        self.head = head
        self.left = left
        self.center = center
        self.right = right
        self.legs = legs
    }
}
