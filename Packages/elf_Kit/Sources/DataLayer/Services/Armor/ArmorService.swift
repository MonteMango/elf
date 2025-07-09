//
//  ArmorService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 04.05.25.
//

import Foundation

public protocol ArmorService {
    func getAllItemsArmor(for itemIds: [UUID]) async -> [BodyPart: Int16]
}
