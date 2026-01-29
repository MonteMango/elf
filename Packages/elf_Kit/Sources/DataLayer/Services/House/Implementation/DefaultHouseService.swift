//
//  DefaultHouseService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 03.12.25.
//

import Foundation

/// Default implementation of HouseService
public final class DefaultHouseService: HouseService {

    // MARK: - Dependencies

    private let elfInfoFactory: ElfInfoFactory

    // MARK: - Properties

    private let templates: [HouseTemplate] = [
        HouseTemplate(name: "Phoenix", logoImageName: "house_phoenix"),
        HouseTemplate(name: "Dragon", logoImageName: "house_dragon"),
        HouseTemplate(name: "Wolf", logoImageName: "house_wolf"),
        HouseTemplate(name: "Eagle", logoImageName: "house_eagle"),
        HouseTemplate(name: "Lion", logoImageName: "house_lion"),
        HouseTemplate(name: "Bear", logoImageName: "house_bear"),
        HouseTemplate(name: "Serpent", logoImageName: "house_serpent"),
        HouseTemplate(name: "Raven", logoImageName: "house_raven")
    ]

    // MARK: - Initialization

    public init(elfInfoFactory: ElfInfoFactory) {
        self.elfInfoFactory = elfInfoFactory
    }

    // MARK: - HouseService

    public func createAllHouses(
        playerElfInfo: ElfInfo
    ) async -> (houses: [House], playerHouseIndex: Int, playerMemberIndex: Int) {
        // Randomly select house and position for the player
        let playerHouseIndex = Int.random(in: 0..<Game.housesCount)
        let playerMemberIndex = Int.random(in: 0..<House.membersCount)

        // Create all 8 houses in parallel
        let houses = await withTaskGroup(of: (Int, House).self) { group in
            for houseIndex in 0..<Game.housesCount {
                group.addTask {
                    let house: House
                    if houseIndex == playerHouseIndex {
                        house = await self.createHouse(
                            templateIndex: houseIndex,
                            level: 1,
                            playerElfInfo: playerElfInfo,
                            playerMemberIndex: playerMemberIndex
                        )
                    } else {
                        house = await self.createHouse(templateIndex: houseIndex, level: 1)
                    }
                    return (houseIndex, house)
                }
            }

            var results: [(Int, House)] = []
            for await result in group {
                results.append(result)
            }
            return results.sorted { $0.0 < $1.0 }.map { $0.1 }
        }

        return (houses, playerHouseIndex, playerMemberIndex)
    }

    // MARK: - Private Helpers

    private func createHouse(templateIndex: Int, level: Int) async -> House {
        precondition(templateIndex >= 0 && templateIndex < templates.count, "Invalid template index")

        let template = templates[templateIndex]

        let members = await withTaskGroup(of: ElfInfo.self) { group in
            for _ in 0..<House.membersCount {
                group.addTask {
                    await self.elfInfoFactory.createRandomAI(level: level)
                }
            }

            var results: [ElfInfo] = []
            for await elf in group {
                results.append(elf)
            }
            return results
        }

        return House(
            name: template.name,
            logoImageName: template.logoImageName,
            members: members
        )
    }

    private func createHouse(
        templateIndex: Int,
        level: Int,
        playerElfInfo: ElfInfo,
        playerMemberIndex: Int
    ) async -> House {
        precondition(templateIndex >= 0 && templateIndex < templates.count, "Invalid template index")
        precondition(playerMemberIndex >= 0 && playerMemberIndex < House.membersCount, "Invalid player member index")

        let template = templates[templateIndex]

        let members = await withTaskGroup(of: (Int, ElfInfo).self) { group in
            for memberIndex in 0..<House.membersCount {
                if memberIndex == playerMemberIndex {
                    group.addTask {
                        (memberIndex, playerElfInfo)
                    }
                } else {
                    group.addTask {
                        let elf = await self.elfInfoFactory.createRandomAI(level: level)
                        return (memberIndex, elf)
                    }
                }
            }

            var results: [(Int, ElfInfo)] = []
            for await result in group {
                results.append(result)
            }
            return results.sorted { $0.0 < $1.0 }.map { $0.1 }
        }

        return House(
            name: template.name,
            logoImageName: template.logoImageName,
            members: members
        )
    }
}
