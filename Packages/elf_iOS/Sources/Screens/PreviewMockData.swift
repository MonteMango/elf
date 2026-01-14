//
//  PreviewMockData.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 04.12.25.
//

import elf_Kit
import Foundation

#if DEBUG

enum PreviewMockData {

    // MARK: - Default Weapon

    private static let defaultWeaponId = UUID(uuidString: "dfbd2742-5470-4f97-84ea-fb17b5f3a6d2")!

    private static func createDefaultEquipped() -> EquippedItems {
        let repository = ElfItemsRepository()
        if let weaponItem = repository.getHeroItem(defaultWeaponId) as? WeaponItem {
            let weapon = ElfWeaponItem(weaponItem: weaponItem)
            return EquippedItems(weapons: .twoHanded(weapon: weapon))
        }
        // Fallback for Preview when HeroItems.json is not available
        let mockWeapon = ElfWeaponItem(weaponItem: createMockWeaponItem())
        return EquippedItems(weapons: .twoHanded(weapon: mockWeapon))
    }

    private static func createMockWeaponItem() -> WeaponItem {
        let json = """
        {
            "id": "dfbd2742-5470-4f97-84ea-fb17b5f3a6d2",
            "title": "Training Sword",
            "tier": 1,
            "minimumAttackPoint": 5,
            "maximumAttackPoint": 10,
            "handUse": "both"
        }
        """
        // swiftlint:disable:next force_try
        return try! JSONDecoder().decode(WeaponItem.self, from: Data(json.utf8))
    }

    // MARK: - Mock Elves

    static func createMockPlayerElfInfo() -> ElfInfo {
        ElfInfo(
            name: "Asuna Yuuki",
            imageName: "elf_appearance_1",
            fightStyle: .dodge,
            currentExp: 0,
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
            currentMP: 23,
            equipped: createDefaultEquipped()
        )
    }

    static func createMockAIElf() -> ElfInfo {
        ElfInfo(
            name: "Luna",
            imageName: "elf_ai_1",
            fightStyle: .crit,
            currentExp: 0,
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
            currentMP: 20,
            equipped: createDefaultEquipped()
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
            actionPoints: ActionPoints.unsafeCreate(current: 100, maximum: 100),
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

    @MainActor
    static func createMockInventoryViewModel() -> InventoryViewModel {
        let gameService = createMockGameService()
        let equipmentService = DefaultEquipmentService(gameService: gameService)
        return InventoryViewModel(
            gameService: gameService,
            equipmentService: equipmentService,
            materialRepository: ElfMaterialRepository()
        )
    }

    static func createMockSnapshotBuilder() -> CombatantSnapshotBuilder {
        let itemsRepository = ElfItemsRepository()
        let armorService = ElfArmorService(itemsRepository: itemsRepository)
        return DefaultCombatantSnapshotBuilder(
            itemsRepository: itemsRepository,
            armorService: armorService
        )
    }
}

#endif
