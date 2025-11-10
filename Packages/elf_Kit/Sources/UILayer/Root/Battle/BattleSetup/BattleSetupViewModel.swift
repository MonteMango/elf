//
//  BattleSetupViewModel.swift
//
//
//  Created by Vitalii Lytvynov on 28.08.24.
//

import Combine
import Foundation

public final class BattleSetupViewModel {
    
    private let rootViewStateDelegate: AnyViewStateDelegate<RootViewState>
    private let battleViewStateDelegate: AnyViewStateDelegate<BattleViewState>
    
    private let attributeService: AttributeService
    private let armorService: ArmorService
    private let damageService: DamageService
    
    private let itemsRepository: ItemsRepository
    
    private var cancellables = Set<AnyCancellable>()
    private var selectHeroItemCancellables = Set<AnyCancellable>()
    
    public init(
        rootViewStateDelegate: AnyViewStateDelegate<RootViewState>,
        battleViewStateDelegate: AnyViewStateDelegate<BattleViewState>,
        attributeService: AttributeService,
        armorService: ArmorService,
        damageService: DamageService,
        itemsRepository: ItemsRepository) {
            self.rootViewStateDelegate = rootViewStateDelegate
            self.battleViewStateDelegate = battleViewStateDelegate
            self.attributeService = attributeService
            self.armorService = armorService
            self.damageService = damageService
            self.itemsRepository = itemsRepository
            
            setupBindings()
        }
    
    @Published public private(set) var viewState: RootViewState = .menu
    @Published public private(set) var playerHeroConfiguration = HeroConfiguration()
    @Published public private(set) var botHeroConfiguration = HeroConfiguration()
    
    public var selectHeroItemViewModel: SelectHeroItemViewModel? {
        didSet {
            selectHeroItemCancellables.removeAll()
            guard let selectHeroItemViewModel = self.selectHeroItemViewModel else { return }
            selectHeroItemViewModel
                .selectedHeroItem
                .sink { [weak self] heroType, heroItemType, itemId in
                    self?.updateHeroConfiguration(for: heroType, itemType: heroItemType, itemId: itemId)
                }
                .store(in: &selectHeroItemCancellables)
        }
    }
    
    // MARK: Methods
    
    public func changeLevel(_ heroType: HeroType, increment: Int16) {
        switch heroType {
        case .player:
            let newLevel = playerHeroConfiguration.level + increment
            guard newLevel >= 1 && newLevel <= 12 else { return }
            playerHeroConfiguration.level = newLevel
        case .bot:
            let newLevel = botHeroConfiguration.level + increment
            guard newLevel >= 1 && newLevel <= 12 else { return }
            botHeroConfiguration.level = newLevel
        }
    }
    
    public func heroItemSelected(for hero: HeroType, heroItemType: HeroItemType) {
        let currentHeroItemId = getCurrentItemId(for: hero, heroItemType: heroItemType)
        battleViewStateDelegate.setViewState(.selectItem(heroType: hero, heroItemType: heroItemType, currentHeroItemId: currentHeroItemId))
    }
    
    public func setHeroFightStyle(for hero: HeroType, fightStyle: FightStyle?) {
        switch hero {
        case .player: playerHeroConfiguration.fightStyle = fightStyle
        case .bot: botHeroConfiguration.fightStyle = fightStyle
        }
    }
    
    // MARK: Actions
    
    @objc
    public func closeButtonAction() {
        rootViewStateDelegate.setViewState(.menu)
    }
    
    @objc
    public func fightButtonAction() {
        battleViewStateDelegate.setViewState(.fight(user: playerHeroConfiguration, enemy: botHeroConfiguration))
    }
    
    // MARK: Private Methods
    
    private func setupBindings() {
        Publishers.CombineLatest(playerHeroConfiguration.$level, playerHeroConfiguration.$fightStyle)
            .sink { [weak self] level, fightStyle in
                guard let self = self else { return }
                self.updateFightStyleAttributes(for: self.playerHeroConfiguration, level: level, fightStyle: fightStyle)
                self.updateRandomLevelAttributes(for: self.playerHeroConfiguration, level: level)
            }
            .store(in: &cancellables)
        
        Publishers.CombineLatest(botHeroConfiguration.$level, botHeroConfiguration.$fightStyle)
            .sink { [weak self] level, fightStyle in
                guard let self = self else { return }
                self.updateFightStyleAttributes(for: self.botHeroConfiguration, level: level, fightStyle: fightStyle)
                self.updateRandomLevelAttributes(for: self.botHeroConfiguration, level: level)
            }
            .store(in: &cancellables)
        
        Publishers.CombineLatest3(playerHeroConfiguration.$fightStyleAttributes, playerHeroConfiguration.$levelRandomAttributes, playerHeroConfiguration.$itemsAttributes)
            .sink { [weak self] playerFightStyleAttributes, playerLevelRandomAttributes, playerItemsAttributes in
                guard let self = self else { return }
                let totalStrength = (playerItemsAttributes?.strength ?? 0) + (playerLevelRandomAttributes?.strength ?? 0) + (playerItemsAttributes?.strength ?? 0)
                self.updateMinMaxStrengthDamage(for: playerHeroConfiguration, strengthAttribute: totalStrength)
            }
            .store(in: &cancellables)
        
        Publishers.CombineLatest3(botHeroConfiguration.$fightStyleAttributes, botHeroConfiguration.$levelRandomAttributes, botHeroConfiguration.$itemsAttributes)
            .sink { [weak self] playerFightStyleAttributes, playerLevelRandomAttributes, playerItemsAttributes in
                guard let self = self else { return }
                let totalStrength = (playerItemsAttributes?.strength ?? 0) + (playerLevelRandomAttributes?.strength ?? 0) + (playerItemsAttributes?.strength ?? 0)
                self.updateMinMaxStrengthDamage(for: botHeroConfiguration, strengthAttribute: totalStrength)
            }
            .store(in: &cancellables)
        
        playerHeroConfiguration
            .$items
            .sink { [weak self] items in
                guard let self = self else { return }
                self.updateItemsArmor(for: self.playerHeroConfiguration)
                self.updateItemsAttributes(for: self.playerHeroConfiguration)
            }
            .store(in: &cancellables)
        
        botHeroConfiguration
            .$items
            .sink { [weak self] items in
                guard let self = self else { return }
                self.updateItemsArmor(for: self.botHeroConfiguration)
                self.updateItemsAttributes(for: self.botHeroConfiguration)
            }
            .store(in: &cancellables)
    }
    
    private func updateFightStyleAttributes(for configuration: HeroConfiguration, level: Int16, fightStyle: FightStyle?) {
        guard let fightStyle = fightStyle else { return }
        Task {
            let updatedAttributes = await attributeService.getAllFightStyleAttributes(for: fightStyle, at: level)
            configuration.fightStyleAttributes = updatedAttributes
        }
    }
    
    private func updateRandomLevelAttributes(for configuration: HeroConfiguration, level: Int16) {
        Task {
            let updateAttributes = await attributeService.getAllRandomLevelAttributes(for: level)
            configuration.levelRandomAttributes = updateAttributes
        }
    }
    
    private func updateItemsAttributes(for configuration: HeroConfiguration) {
        Task {
            let itemIds = getItemIdsFromHeroConfigurationItems(configuration.items)
            let updateAttributes = await attributeService.getAllItemsAttrbutes(for: itemIds)
            configuration.itemsAttributes = updateAttributes
        }
    }
    
    private func updateMinMaxStrengthDamage(for configuration: HeroConfiguration, strengthAttribute: Int16) {
        Task {
            var totalStrength = (configuration.fightStyleAttributes?.strength ?? 0) + (configuration.levelRandomAttributes?.strength ?? 0) + (configuration.itemsAttributes?.strength ?? 0)
            
            if case .leftSecondaryRightSecondary = configuration.items.handsUse {
                totalStrength = totalStrength / 2
            }
            
            configuration.minMaxStrengthDamage = await damageService.getMinMaxStrengthDamage(totalStrength)
        }
    }
    
    private func updateItemsArmor(for configuration: HeroConfiguration) {
        Task {
            let itemIds = getItemIdsFromHeroConfigurationItems(configuration.items)
            let updateArmor = await armorService.getAllItemsArmor(for: itemIds)
            configuration.itemsArmor = updateArmor
        }
    }
    
    private func updateHeroConfiguration(for heroType: HeroType, itemType: HeroItemType, itemId: UUID?) {
        Task {
            let configuration = heroType == .player ? playerHeroConfiguration : botHeroConfiguration
            
            switch itemType {
            case .helmet:
                if let itemId = itemId, let item = await itemsRepository.getHeroItem(itemId) {
                    guard let defenseItem = item as? DefenseItem else { return }
                    configuration.items.helmet = ElfDefenseItem(defenseItem: defenseItem)
                } else {
                    configuration.items.helmet = nil
                }
                
            case .gloves:
                if let itemId = itemId, let item = await itemsRepository.getHeroItem(itemId) {
                    guard let defenseItem = item as? DefenseItem else { return }
                    configuration.items.gloves = ElfDefenseItem(defenseItem: defenseItem)
                } else {
                    configuration.items.gloves = nil
                }
            case .shoes:
                if let itemId = itemId, let item = await itemsRepository.getHeroItem(itemId) {
                    guard let defenseItem = item as? DefenseItem else { return }
                    configuration.items.shoes = ElfDefenseItem(defenseItem: defenseItem)
                } else {
                    configuration.items.shoes = nil
                }
            case .upperBody:
                if let itemId = itemId, let item = await itemsRepository.getHeroItem(itemId) {
                    guard let defenseItem = item as? DefenseItem else { return }
                    configuration.items.upperBody = ElfDefenseItem(defenseItem: defenseItem)
                } else {
                    configuration.items.upperBody = nil
                }
            case .bottomBody:
                if let itemId = itemId, let item = await itemsRepository.getHeroItem(itemId) {
                    guard let defenseItem = item as? DefenseItem else { return }
                    configuration.items.bottomBody = ElfDefenseItem(defenseItem: defenseItem)
                } else {
                    configuration.items.bottomBody = nil
                }
            case .shirt:
                if let itemId = itemId, let item = await itemsRepository.getHeroItem(itemId) {
                    guard let robeItem = item as? RobeItem else { return }
                    configuration.items.shirt = ElfRobeItem(robeItem: robeItem)
                } else {
                    configuration.items.shirt = nil
                }
            case .ring:
                if let itemId = itemId, let item = await itemsRepository.getHeroItem(itemId) {
                    guard let jewelryItem = item as? JewelryItem else { return }
                    configuration.items.ring = ElfJewelryItem(jewelryItem: jewelryItem)
                } else {
                    configuration.items.ring = nil
                }
            case .necklace:
                if let itemId = itemId, let item = await itemsRepository.getHeroItem(itemId) {
                    guard let jewelryItem = item as? JewelryItem else { return }
                    configuration.items.necklace = ElfJewelryItem(jewelryItem: jewelryItem)
                } else {
                    configuration.items.necklace = nil
                }
            case .earrings:
                if let itemId = itemId, let item = await itemsRepository.getHeroItem(itemId) {
                    guard let jewelryItem = item as? JewelryItem else { return }
                    configuration.items.earrings = ElfJewelryItem(jewelryItem: jewelryItem)
                } else {
                    configuration.items.earrings = nil
                }
            case .weapons:
                switch configuration.items.handsUse {
                case .noWeapon:
                    if let itemId = itemId, let item = await itemsRepository.getHeroItem(itemId) {
                        guard let item = item as? WeaponItem else { return }
                        switch item.handUse {
                        case .primary:
                            configuration.items.handsUse = .leftPrimaryRightEmpty(primaryWeapon: ElfWeaponItem(weaponItem: item))
                        case .secondary:
                            configuration.items.handsUse = .leftSecondaryRightEmpty(secondaryWeapon: ElfWeaponItem(weaponItem: item))
                        case .both:
                            configuration.items.handsUse = .twoHandsWeapon(twoHandsweapon: ElfWeaponItem(weaponItem: item))
                        }
                    } else {
                        configuration.items.handsUse = .noWeapon
                    }
                case .twoHandsWeapon:
                    if let itemId = itemId, let item = await itemsRepository.getHeroItem(itemId) {
                        guard let item = item as? WeaponItem else { return }
                        switch item.handUse {
                        case .primary:
                            configuration.items.handsUse = .leftPrimaryRightEmpty(primaryWeapon: ElfWeaponItem(weaponItem: item))
                        case .secondary:
                            configuration.items.handsUse = .leftSecondaryRightEmpty(secondaryWeapon: ElfWeaponItem(weaponItem: item))
                        case .both:
                            configuration.items.handsUse = .twoHandsWeapon(twoHandsweapon: ElfWeaponItem(weaponItem: item))
                        }
                    } else {
                        configuration.items.handsUse = .noWeapon
                    }
                case .leftPrimaryRightEmpty:
                    if let itemId = itemId, let item = await itemsRepository.getHeroItem(itemId) {
                        guard let item = item as? WeaponItem else { return }
                        switch item.handUse {
                        case .primary:
                            configuration.items.handsUse = .leftPrimaryRightEmpty(primaryWeapon: ElfWeaponItem(weaponItem: item))
                        case .secondary:
                            configuration.items.handsUse = .leftSecondaryRightEmpty(secondaryWeapon: ElfWeaponItem(weaponItem: item))
                        case .both:
                            configuration.items.handsUse = .twoHandsWeapon(twoHandsweapon: ElfWeaponItem(weaponItem: item))
                        }
                    } else {
                        configuration.items.handsUse = .noWeapon
                    }
                case .leftPrimaryRightShield(_, shield: let shield):
                    if let itemId = itemId, let item = await itemsRepository.getHeroItem(itemId) {
                        guard let item = item as? WeaponItem else { return }
                        switch item.handUse {
                        case .primary:
                            configuration.items.handsUse = .leftPrimaryRightShield(primaryWeapon: ElfWeaponItem(weaponItem: item), shield: shield)
                        case .secondary:
                            configuration.items.handsUse = .leftSecondaryRightShield(secondaryWeapon: ElfWeaponItem(weaponItem: item), shield: shield)
                        case .both:
                            configuration.items.handsUse = .twoHandsWeapon(twoHandsweapon: ElfWeaponItem(weaponItem: item))
                        }
                    } else {
                        configuration.items.handsUse = .leftEmptyRigthShield(shield: shield)
                    }
                case .leftSecondaryRightEmpty:
                    if let itemId = itemId, let item = await itemsRepository.getHeroItem(itemId) {
                        guard let item = item as? WeaponItem else { return }
                        switch item.handUse {
                        case .primary:
                            configuration.items.handsUse = .leftPrimaryRightEmpty(primaryWeapon: ElfWeaponItem(weaponItem: item))
                        case .secondary:
                            configuration.items.handsUse = .leftSecondaryRightEmpty(secondaryWeapon: ElfWeaponItem(weaponItem: item))
                        case .both:
                            configuration.items.handsUse = .twoHandsWeapon(twoHandsweapon: ElfWeaponItem(weaponItem: item))
                        }
                    } else {
                        configuration.items.handsUse = .noWeapon
                    }
                case .leftEmptyRightSecondary(secondaryWeapon: let secondaryWeapon):
                    if let itemId = itemId, let item = await itemsRepository.getHeroItem(itemId) {
                        guard let item = item as? WeaponItem else { return }
                        switch item.handUse {
                        case .primary:
                            configuration.items.handsUse = .leftPrimaryRightEmpty(primaryWeapon: ElfWeaponItem(weaponItem: item))
                        case .secondary:
                            configuration.items.handsUse = .leftSecondaryRightSecondary(leftSecondaryWeapon: ElfWeaponItem(weaponItem: item), rightSecondaryWeapon: secondaryWeapon)
                        case .both:
                            configuration.items.handsUse = .twoHandsWeapon(twoHandsweapon: ElfWeaponItem(weaponItem: item))
                        }
                    } else {
                        configuration.items.handsUse = .leftEmptyRightSecondary(secondaryWeapon: secondaryWeapon)
                    }
                case .leftSecondaryRightSecondary(_, rightSecondaryWeapon: let rightSecondaryWeapon):
                    if let itemId = itemId, let item = await itemsRepository.getHeroItem(itemId) {
                        guard let item = item as? WeaponItem else { return }
                        switch item.handUse {
                        case .primary:
                            configuration.items.handsUse = .leftPrimaryRightEmpty(primaryWeapon: ElfWeaponItem(weaponItem: item))
                        case .secondary:
                            configuration.items.handsUse = .leftSecondaryRightSecondary(leftSecondaryWeapon: ElfWeaponItem(weaponItem: item), rightSecondaryWeapon: rightSecondaryWeapon)
                        case .both:
                            configuration.items.handsUse = .twoHandsWeapon(twoHandsweapon: ElfWeaponItem(weaponItem: item))
                        }
                    } else {
                        configuration.items.handsUse = .leftEmptyRightSecondary(secondaryWeapon: rightSecondaryWeapon)
                    }
                case .leftSecondaryRightShield(_, shield: let shield):
                    if let itemId = itemId, let item = await itemsRepository.getHeroItem(itemId) {
                        guard let item = item as? WeaponItem else { return }
                        switch item.handUse {
                        case .primary:
                            configuration.items.handsUse = .leftPrimaryRightShield(primaryWeapon: ElfWeaponItem(weaponItem: item), shield: shield)
                        case .secondary:
                            configuration.items.handsUse = .leftSecondaryRightShield(secondaryWeapon: ElfWeaponItem(weaponItem: item), shield: shield)
                        case .both:
                            configuration.items.handsUse = .twoHandsWeapon(twoHandsweapon: ElfWeaponItem(weaponItem: item))
                        }
                    } else {
                        configuration.items.handsUse = .leftEmptyRigthShield(shield: shield)
                    }
                case .leftEmptyRigthShield(shield: let shield):
                    if let itemId = itemId, let item = await itemsRepository.getHeroItem(itemId) {
                        guard let item = item as? WeaponItem else { return }
                        switch item.handUse {
                        case .primary:
                            configuration.items.handsUse = .leftPrimaryRightShield(primaryWeapon: ElfWeaponItem(weaponItem: item), shield: shield)
                        case .secondary:
                            configuration.items.handsUse = .leftSecondaryRightShield(secondaryWeapon: ElfWeaponItem(weaponItem: item), shield: shield)
                        case .both:
                            configuration.items.handsUse = .twoHandsWeapon(twoHandsweapon: ElfWeaponItem(weaponItem: item))
                        }
                    } else {
                        configuration.items.handsUse = .leftEmptyRigthShield(shield: shield)
                    }
                }
            case .shields:
                switch configuration.items.handsUse {
                case .noWeapon:
                    if let itemId = itemId, let item = await itemsRepository.getHeroItem(itemId) {
                        if let item = item as? ShieldItem {
                            configuration.items.handsUse = .leftEmptyRigthShield(shield: ElfShieldItem(shieldItem: item))
                        }
                        
                        if let item = item as? WeaponItem {
                            switch item.handUse {
                            case .primary:
                                configuration.items.handsUse = .noWeapon
                            case .secondary:
                                configuration.items.handsUse = .leftEmptyRightSecondary(secondaryWeapon: ElfWeaponItem(weaponItem: item))
                            case .both:
                                configuration.items.handsUse = .noWeapon
                            }
                        }
                    } else {
                        configuration.items.handsUse = .noWeapon
                    }
                case .twoHandsWeapon:
                    if let itemId = itemId, let item = await itemsRepository.getHeroItem(itemId) {
                        if let item = item as? ShieldItem {
                            configuration.items.handsUse = .leftEmptyRigthShield(shield: ElfShieldItem(shieldItem: item))
                        }
                        
                        if let item = item as? WeaponItem {
                            switch item.handUse {
                            case .primary:
                                configuration.items.handsUse = .noWeapon
                            case .secondary:
                                configuration.items.handsUse = .leftEmptyRightSecondary(secondaryWeapon: ElfWeaponItem(weaponItem: item))
                            case .both:
                                configuration.items.handsUse = .noWeapon
                            }
                        }
                    } else {
                        configuration.items.handsUse = .noWeapon
                    }
                case .leftPrimaryRightEmpty(primaryWeapon: let primaryWeapon):
                    if let itemId = itemId, let item = await itemsRepository.getHeroItem(itemId) {
                        if let item = item as? ShieldItem {
                            configuration.items.handsUse = .leftPrimaryRightShield(primaryWeapon: primaryWeapon, shield: ElfShieldItem(shieldItem: item))
                        }
                        
                        if let item = item as? WeaponItem {
                            switch item.handUse {
                            case .primary:
                                configuration.items.handsUse = .noWeapon
                            case .secondary:
                                configuration.items.handsUse = .leftEmptyRightSecondary(secondaryWeapon: ElfWeaponItem(weaponItem: item))
                            case .both:
                                configuration.items.handsUse = .noWeapon
                            }
                        }
                    } else {
                        configuration.items.handsUse = .leftPrimaryRightEmpty(primaryWeapon: primaryWeapon)
                    }
                case .leftPrimaryRightShield(primaryWeapon: let primaryWeapon, _):
                    if let itemId = itemId, let item = await itemsRepository.getHeroItem(itemId) {
                        if let item = item as? ShieldItem {
                            configuration.items.handsUse = .leftPrimaryRightShield(primaryWeapon: primaryWeapon, shield: ElfShieldItem(shieldItem: item))
                        }
                        
                        if let item = item as? WeaponItem {
                            switch item.handUse {
                            case .primary:
                                configuration.items.handsUse = .noWeapon
                            case .secondary:
                                configuration.items.handsUse = .leftEmptyRightSecondary(secondaryWeapon: ElfWeaponItem(weaponItem: item))
                            case .both:
                                configuration.items.handsUse = .noWeapon
                            }
                        }
                    } else {
                        configuration.items.handsUse = .leftPrimaryRightEmpty(primaryWeapon: primaryWeapon)
                    }
                case .leftSecondaryRightEmpty(secondaryWeapon: let secondaryWeapon):
                    if let itemId = itemId, let item = await itemsRepository.getHeroItem(itemId) {
                        if let item = item as? ShieldItem {
                            configuration.items.handsUse = .leftSecondaryRightShield(secondaryWeapon: secondaryWeapon, shield: ElfShieldItem(shieldItem: item))
                        }
                        
                        if let item = item as? WeaponItem {
                            switch item.handUse {
                            case .primary:
                                configuration.items.handsUse = .noWeapon
                            case .secondary:
                                configuration.items.handsUse = .leftSecondaryRightSecondary(leftSecondaryWeapon: secondaryWeapon, rightSecondaryWeapon: ElfWeaponItem(weaponItem: item))
                            case .both:
                                configuration.items.handsUse = .noWeapon
                            }
                        }
                    } else {
                        configuration.items.handsUse = .leftSecondaryRightEmpty(secondaryWeapon: secondaryWeapon)
                    }
                case .leftEmptyRightSecondary:
                    if let itemId = itemId, let item = await itemsRepository.getHeroItem(itemId) {
                        if let item = item as? ShieldItem {
                            configuration.items.handsUse = .leftEmptyRigthShield(shield: ElfShieldItem(shieldItem: item))
                        }
                        
                        if let item = item as? WeaponItem {
                            switch item.handUse {
                            case .primary:
                                configuration.items.handsUse = .noWeapon
                            case .secondary:
                                configuration.items.handsUse = .leftEmptyRightSecondary(secondaryWeapon: ElfWeaponItem(weaponItem: item))
                            case .both:
                                configuration.items.handsUse = .noWeapon
                            }
                        }
                    } else {
                        configuration.items.handsUse = .noWeapon
                    }
                case .leftSecondaryRightSecondary(leftSecondaryWeapon: let leftSecondaryWeapon, _):
                    if let itemId = itemId, let item = await itemsRepository.getHeroItem(itemId) {
                        if let item = item as? ShieldItem {
                            configuration.items.handsUse = .leftSecondaryRightShield(secondaryWeapon:leftSecondaryWeapon, shield: ElfShieldItem(shieldItem: item))
                        }
                        
                        if let item = item as? WeaponItem {
                            switch item.handUse {
                            case .primary:
                                configuration.items.handsUse = .noWeapon
                            case .secondary:
                                configuration.items.handsUse = .leftSecondaryRightSecondary(leftSecondaryWeapon: leftSecondaryWeapon, rightSecondaryWeapon: ElfWeaponItem(weaponItem: item))
                            case .both:
                                configuration.items.handsUse = .noWeapon
                            }
                        }
                    } else {
                        configuration.items.handsUse = .leftSecondaryRightEmpty(secondaryWeapon: leftSecondaryWeapon)
                    }
                case .leftSecondaryRightShield(secondaryWeapon: let secondaryWeapon, _):
                    if let itemId = itemId, let item = await itemsRepository.getHeroItem(itemId) {
                        if let item = item as? ShieldItem {
                            configuration.items.handsUse = .leftSecondaryRightShield(secondaryWeapon: secondaryWeapon, shield: ElfShieldItem(shieldItem: item))
                        }
                        
                        if let item = item as? WeaponItem {
                            switch item.handUse {
                            case .primary:
                                configuration.items.handsUse = .noWeapon
                            case .secondary:
                                configuration.items.handsUse = .leftSecondaryRightSecondary(leftSecondaryWeapon: secondaryWeapon, rightSecondaryWeapon: ElfWeaponItem(weaponItem: item))
                            case .both:
                                configuration.items.handsUse = .noWeapon
                            }
                        }
                    } else {
                        configuration.items.handsUse = .leftSecondaryRightEmpty(secondaryWeapon: secondaryWeapon)
                    }
                case .leftEmptyRigthShield:
                    if let itemId = itemId, let item = await itemsRepository.getHeroItem(itemId) {
                        if let item = item as? ShieldItem {
                            configuration.items.handsUse = .leftEmptyRigthShield(shield: ElfShieldItem(shieldItem: item))
                        }
                        
                        if let item = item as? WeaponItem {
                            switch item.handUse {
                            case .primary:
                                configuration.items.handsUse = .noWeapon
                            case .secondary:
                                configuration.items.handsUse = .leftEmptyRightSecondary(secondaryWeapon: ElfWeaponItem(weaponItem: item))
                            case .both:
                                configuration.items.handsUse = .noWeapon
                            }
                        }
                    } else {
                        configuration.items.handsUse = .noWeapon
                    }
                }
            }
        }
    }
    
    private func getCurrentItemId(for hero: HeroType, heroItemType: HeroItemType) -> UUID? {
        let configuration = hero == .player ? playerHeroConfiguration : botHeroConfiguration
        switch heroItemType {
        case .helmet: return configuration.items.helmet?.item.id
        case .gloves: return configuration.items.gloves?.item.id
        case .shoes: return configuration.items.shoes?.item.id
        case .upperBody: return configuration.items.upperBody?.item.id
        case .bottomBody: return configuration.items.bottomBody?.item.id
        case .shirt: return configuration.items.shirt?.item.id
        case .ring: return configuration.items.ring?.item.id
        case .necklace: return configuration.items.necklace?.item.id
        case .earrings: return configuration.items.earrings?.item.id
        case .weapons:
            switch configuration.items.handsUse {
            case .twoHandsWeapon(let twoHandsweapon):
                return twoHandsweapon.item.id
            case .leftPrimaryRightEmpty(let primaryWeapon):
                return primaryWeapon.item.id
            case .leftPrimaryRightShield(let primaryWeapon, _):
                return primaryWeapon.item.id
            case .leftSecondaryRightEmpty(let secondaryWeapon):
                return secondaryWeapon.item.id
            case .leftSecondaryRightSecondary(let leftSecondaryWeapon, _):
                return leftSecondaryWeapon.item.id
            case .leftSecondaryRightShield(let secondaryWeapon, _):
                return secondaryWeapon.item.id
            default: return nil
            }
        case .shields:
            switch configuration.items.handsUse {
            case .leftPrimaryRightShield(_, let shield):
                return shield.item.id
            case .leftEmptyRightSecondary(let secondaryWeapon):
                return secondaryWeapon.item.id
            case .leftSecondaryRightSecondary(_, let rightSecondfaryWeapon):
                return rightSecondfaryWeapon.item.id
            case .leftSecondaryRightShield(_, let shield):
                return shield.item.id
            case .leftEmptyRigthShield(shield: let shield):
                return shield.item.id
            default: return nil
            }
        }
    }
    
    private func getItemIdsFromHeroConfigurationItems(_ items: HeroConfigurationItems) -> [UUID] {
        var itemIds: [UUID] = []
        
        if let helmetId = items.helmet?.item.id { itemIds.append(helmetId) }
        if let glovesId = items.gloves?.item.id { itemIds.append(glovesId) }
        if let shoesId = items.shoes?.item.id { itemIds.append(shoesId) }
        if let upperBodyId = items.upperBody?.item.id { itemIds.append(upperBodyId) }
        if let bottomBodyId = items.bottomBody?.item.id { itemIds.append(bottomBodyId) }
        if let shirtId = items.shirt?.item.id { itemIds.append(shirtId) }
        if let ringId = items.ring?.item.id { itemIds.append(ringId) }
        if let necklaceId = items.necklace?.item.id { itemIds.append(necklaceId) }
        if let earringsId = items.earrings?.item.id { itemIds.append(earringsId) }
        
        switch items.handsUse {
        case .noWeapon:
            break
        case .twoHandsWeapon(let weapon):
            itemIds.append(weapon.item.id)
        case .leftPrimaryRightEmpty(let weapon):
            itemIds.append(weapon.item.id)
        case .leftPrimaryRightShield(let weapon, let shield):
            itemIds.append(weapon.item.id)
            itemIds.append(shield.item.id)
        case .leftSecondaryRightEmpty(let weapon):
            itemIds.append(weapon.item.id)
        case .leftEmptyRightSecondary(let weapon):
            itemIds.append(weapon.item.id)
        case .leftSecondaryRightSecondary(let leftSecondaryWeapon, let rightSecondfaryWeapon):
            itemIds.append(leftSecondaryWeapon.item.id)
            itemIds.append(rightSecondfaryWeapon.item.id)
        case .leftSecondaryRightShield(let weapon, let shield):
            itemIds.append(weapon.item.id)
            itemIds.append(shield.item.id)
        case .leftEmptyRigthShield(let shield):
            itemIds.append(shield.item.id)
        }
        
        return itemIds
    }
}
