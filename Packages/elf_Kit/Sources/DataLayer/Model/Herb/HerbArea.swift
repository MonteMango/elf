//
//  HerbArea.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

public struct HerbArea: Codable, Sendable {
    public let title: String
    public let herbs: [HerbID]
}
