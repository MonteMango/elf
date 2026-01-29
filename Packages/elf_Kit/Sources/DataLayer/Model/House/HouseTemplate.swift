//
//  HouseTemplate.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 03.12.25.
//

import Foundation

/// Template for house creation containing name and logo
struct HouseTemplate: Sendable {
    let name: String
    let logoImageName: String

    init(name: String, logoImageName: String) {
        self.name = name
        self.logoImageName = logoImageName
    }
}
