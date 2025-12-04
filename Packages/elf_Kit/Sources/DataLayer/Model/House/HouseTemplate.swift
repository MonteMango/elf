//
//  HouseTemplate.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 03.12.25.
//

import Foundation

/// Template for house creation containing name and logo
public struct HouseTemplate: Sendable {
    public let name: String
    public let logoImageName: String

    public init(name: String, logoImageName: String) {
        self.name = name
        self.logoImageName = logoImageName
    }
}
