//
//  DataLoader.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 09.07.25.
//

import Foundation

public protocol DataLoader {
    func loadHeroItemsData() async throws -> Data
}
