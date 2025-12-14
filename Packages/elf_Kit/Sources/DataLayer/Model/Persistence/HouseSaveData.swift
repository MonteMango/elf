//
//  HouseSaveData.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 04.12.25.
//

import Foundation

public struct HouseSaveData: Codable, Sendable {
    public let id: UUID
    public let name: String
    public let logoImageName: String
    public let isEliminated: Bool
    public let members: [ElfSaveData]

    public init(from house: House) {
        self.id = house.id
        self.name = house.name
        self.logoImageName = house.logoImageName
        self.isEliminated = house.isEliminated
        self.members = house.members.map { ElfSaveData(from: $0) }
    }

    public func toHouse(itemsRepository: ItemsRepository) throws -> House {
        House(
            id: id,
            name: name,
            logoImageName: logoImageName,
            isEliminated: isEliminated,
            members: try members.map { try $0.toElfInfo(itemsRepository: itemsRepository) }
        )
    }
}
