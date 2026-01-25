//
//  DataLoader.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 09.07.25.
//

import Foundation

public protocol DataLoader {
    func loadHeroItemsData() throws -> Data
    func loadMonstersData() throws -> Data
    func loadMaterialsData() throws -> Data
    func loadFishData() throws -> Data
}
