//
//  PreviewMockData.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 04.12.25.
//

import elf_Kit

#if DEBUG

enum PreviewMockData {

    static func createMockPlayerElfInfo() -> ElfInfo {
        ElfInfo(
            name: "Asuna Yuuki",
            imageName: "elf_appearance_1",
            fightStyle: .dodge,
            level: 1,
            currentExp: 0,
            expToNextLevel: 100,
            fightStyleAttributes: HeroAttributes(
                hitPoints: 80,
                manaPoints: 20,
                agility: 4,
                strength: 1,
                power: 0,
                instinct: 1
            ),
            randomLevelAttributes: HeroAttributes(
                hitPoints: 3,
                manaPoints: 3,
                agility: 1,
                strength: 0,
                power: 0,
                instinct: 0
            ),
            currentHP: 83,
            currentMP: 23
        )
    }

    static func createMockAIElf() -> ElfInfo {
        ElfInfo(
            name: "Luna",
            imageName: "elf_ai_1",
            fightStyle: .crit,
            level: 1,
            currentExp: 0,
            expToNextLevel: 100,
            fightStyleAttributes: HeroAttributes(
                hitPoints: 80,
                manaPoints: 20,
                agility: 0,
                strength: 1,
                power: 4,
                instinct: 1
            ),
            randomLevelAttributes: HeroAttributes(
                hitPoints: 0,
                manaPoints: 0,
                agility: 1,
                strength: 1,
                power: 1,
                instinct: 1
            ),
            currentHP: 80,
            currentMP: 20
        )
    }

    static func createMockGame() -> Game {
        let playerElfInfo = createMockPlayerElfInfo()

        let houseTemplates = [
            ("Phoenix", "house_phoenix"),
            ("Dragon", "house_dragon"),
            ("Wolf", "house_wolf"),
            ("Eagle", "house_eagle"),
            ("Lion", "house_lion"),
            ("Bear", "house_bear"),
            ("Serpent", "house_serpent"),
            ("Raven", "house_raven")
        ]

        let playerHouseIndex = 0
        let playerMemberIndex = 0

        var houses: [House] = []
        for (index, template) in houseTemplates.enumerated() {
            var members: [ElfInfo] = []
            for memberIndex in 0..<House.membersCount {
                if index == playerHouseIndex && memberIndex == playerMemberIndex {
                    members.append(playerElfInfo)
                } else {
                    members.append(createMockAIElf())
                }
            }
            houses.append(House(name: template.0, logoImageName: template.1, members: members))
        }

        let calendarService = DefaultCalendarService()
        let calendar = calendarService.generateFullCalendar()
        let firstDay = calendar.first ?? GameDay(dayNumber: 1, dayType: .normal)

        let gameState = GameState(
            currentDay: firstDay,
            currentActionPoints: 100,
            maxActionPoints: 100,
            calendar: calendar
        )

        return Game(
            houses: houses,
            gameState: gameState,
            playerHouseIndex: playerHouseIndex,
            playerMemberIndex: playerMemberIndex
        )
    }

    @MainActor
    static func createMockGameService() -> GameService {
        DefaultGameService(game: createMockGame())
    }

    @MainActor
    static func createMockGameDayViewModel() -> GameDayViewModel {
        GameDayViewModel(gameService: createMockGameService())
    }
}

#endif
