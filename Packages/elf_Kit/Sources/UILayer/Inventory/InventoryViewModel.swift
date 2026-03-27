//
//  InventoryViewModel.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

@Observable
@MainActor
public final class InventoryViewModel {

    // MARK: - Dependencies

    let gameService: any GameService
    let equipmentService: any EquipmentService
    let materialRepository: any Repository<Material>
    let equipmentQueryService: any EquipmentQueryService

    // MARK: - State

    public var selectedCategory: InventoryCategory = .weapons
    public var selectedWeaponSubcategory: WeaponSubcategory = .all
    public var selectedArmorSubcategory: ArmorSubcategory = .all
    public var selectedPotionScrollSubcategory: PotionScrollSubcategory = .all
    public var selectedMaterialSubcategory: MaterialSubcategory = .all

    public var selectedItemId: UUID?

    // MARK: - Callbacks

    public var onClose: () -> Void = {}

    // MARK: - Internal Access

    var player: ElfInfo {
        gameService.game.player
    }

    // MARK: - Cached State

    private var cachedItems: [InventoryDisplayItem] = []

    public var filteredItems: [InventoryDisplayItem] {
        cachedItems.filter { item in
            guard item.category == selectedCategory else { return false }
            return passesSubcategoryFilter(item)
        }
    }

    public var selectedItem: InventoryDisplayItem? {
        guard let id = selectedItemId else { return nil }
        return cachedItems.first { $0.id == id }
    }

    public var currentSubcategoryTitles: [String] {
        switch selectedCategory {
        case .weapons:
            return WeaponSubcategory.allCases.map { $0.displayTitle }
        case .armor:
            return ArmorSubcategory.allCases.map { $0.displayTitle }
        case .potionsScrolls:
            return PotionScrollSubcategory.allCases.map { $0.displayTitle }
        case .materials:
            return MaterialSubcategory.allCases.map { $0.displayTitle }
        }
    }

    public var selectedSubcategoryIndex: Int {
        switch selectedCategory {
        case .weapons:
            return WeaponSubcategory.allCases.firstIndex(of: selectedWeaponSubcategory) ?? 0
        case .armor:
            return ArmorSubcategory.allCases.firstIndex(of: selectedArmorSubcategory) ?? 0
        case .potionsScrolls:
            return PotionScrollSubcategory.allCases.firstIndex(of: selectedPotionScrollSubcategory) ?? 0
        case .materials:
            return MaterialSubcategory.allCases.firstIndex(of: selectedMaterialSubcategory) ?? 0
        }
    }

    // MARK: - Initialization

    public init(
        gameService: any GameService,
        equipmentService: any EquipmentService,
        materialRepository: any Repository<Material>,
        equipmentQueryService: any EquipmentQueryService
    ) {
        self.gameService = gameService
        self.equipmentService = equipmentService
        self.materialRepository = materialRepository
        self.equipmentQueryService = equipmentQueryService
    }

    // MARK: - Data Loading

    /// Refreshes display items from repositories. Call from View's .task {} modifier.
    public func refreshItems() async {
        cachedItems = await buildDisplayItems()
    }

    // MARK: - Actions

    public func selectCategory(_ category: InventoryCategory) {
        selectedCategory = category
        selectedItemId = nil
    }

    public func selectSubcategory(at index: Int) {
        switch selectedCategory {
        case .weapons:
            if let sub = WeaponSubcategory.allCases[safe: index] {
                selectedWeaponSubcategory = sub
            }
        case .armor:
            if let sub = ArmorSubcategory.allCases[safe: index] {
                selectedArmorSubcategory = sub
            }
        case .potionsScrolls:
            if let sub = PotionScrollSubcategory.allCases[safe: index] {
                selectedPotionScrollSubcategory = sub
            }
        case .materials:
            if let sub = MaterialSubcategory.allCases[safe: index] {
                selectedMaterialSubcategory = sub
            }
        }
        selectedItemId = nil
    }

    public func selectItem(_ item: InventoryDisplayItem) {
        selectedItemId = item.id
    }

    /// Select item by ID, switching category and resetting subcategory to "all"
    public func selectItemById(_ itemId: UUID?) {
        guard let itemId = itemId else { return }

        guard let item = cachedItems.first(where: { $0.id == itemId }) else { return }

        // Switch category if needed
        if selectedCategory != item.category {
            selectedCategory = item.category
            resetSubcategoryToAll(for: item.category)
        }

        selectedItemId = itemId
    }

    private func resetSubcategoryToAll(for category: InventoryCategory) {
        switch category {
        case .weapons:
            selectedWeaponSubcategory = .all
        case .armor:
            selectedArmorSubcategory = .all
        case .potionsScrolls:
            selectedPotionScrollSubcategory = .all
        case .materials:
            selectedMaterialSubcategory = .all
        }
    }

    public func equipSelectedItem() {
        guard let item = selectedItem, !item.isEquipped else { return }
        equipItem(item)
    }

    public func unequipSelectedItem() {
        guard let item = selectedItem, item.isEquipped else { return }
        unequipItem(item)
    }

    public func closeInventory() {
        onClose()
    }

    // MARK: - Private Helpers

    private func passesSubcategoryFilter(_ item: InventoryDisplayItem) -> Bool {
        switch selectedCategory {
        case .weapons:
            guard selectedWeaponSubcategory != .all else { return true }
            switch item.itemDetails {
            case .weapon(let details):
                return matchesWeaponSubcategory(details, selectedWeaponSubcategory)
            case .shield:
                return selectedWeaponSubcategory == .shields
            default:
                return false
            }

        case .armor:
            guard selectedArmorSubcategory != .all else { return true }
            switch item.itemDetails {
            case .armor:
                return selectedArmorSubcategory == .armor
            case .jewelry:
                return selectedArmorSubcategory == .jewelry
            default:
                return false
            }

        case .potionsScrolls:
            return true

        case .materials:
            guard selectedMaterialSubcategory != .all else { return true }
            switch item.itemDetails {
            case .material(let details):
                return details.subcategory == selectedMaterialSubcategory
            default:
                return false
            }
        }
    }

    private func matchesWeaponSubcategory(_ details: WeaponDetails, _ sub: WeaponSubcategory) -> Bool {
        switch sub {
        case .all: return true
        case .oneHand: return details.handUse.lowercased().contains("one")
        case .twoHands: return details.handUse.lowercased().contains("two")
        case .shields: return false
        }
    }
}

// MARK: - Array Extension

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
