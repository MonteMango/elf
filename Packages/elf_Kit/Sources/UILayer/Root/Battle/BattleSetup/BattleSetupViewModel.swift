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
    
    private var cancellables = Set<AnyCancellable>()
    private var selectHeroItemCancellables = Set<AnyCancellable>()
    
    public init(
        rootViewStateDelegate: AnyViewStateDelegate<RootViewState>,
        battleViewStateDelegate: AnyViewStateDelegate<BattleViewState>,
        attributeService: AttributeService) {
            self.rootViewStateDelegate = rootViewStateDelegate
            self.battleViewStateDelegate = battleViewStateDelegate
            self.attributeService = attributeService
            
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
                .sink { [weak self] heroType, heroItemType, itemId, blockingTwoHandsWeaponId in
                    self?.updateHeroConfiguration(for: heroType, itemType: heroItemType, itemId: itemId, blockingTwoHandsWeaponId: blockingTwoHandsWeaponId)
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
    
    // MARK: Private Methods
    
    private func setupBindings() {
        // Track changes in playerHeroConfiguration
        Publishers.CombineLatest3(playerHeroConfiguration.$level, playerHeroConfiguration.$fightStyle, playerHeroConfiguration.$itemIds)
            .sink { [weak self] level, fightStyle, itemIds in
                guard let self = self else { return }
                self.updateFightStyleAttributes(for: self.playerHeroConfiguration, level: level, fightStyle: fightStyle)
                self.updateRandomLevelAttributes(for: self.playerHeroConfiguration, level: level)
                self.updateItemsAttributes(for: self.playerHeroConfiguration, itemIds: itemIds)
            }
            .store(in: &cancellables)
        
        // Track changes in botHeroConfiguration
        Publishers.CombineLatest3(botHeroConfiguration.$level, botHeroConfiguration.$fightStyle, botHeroConfiguration.$itemIds)
            .sink { [weak self] level, fightStyle, itemIds in
                guard let self = self else { return }
                self.updateFightStyleAttributes(for: self.botHeroConfiguration, level: level, fightStyle: fightStyle)
                self.updateRandomLevelAttributes(for: self.botHeroConfiguration, level: level)
                self.updateItemsAttributes(for: self.botHeroConfiguration, itemIds: itemIds)
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
    
    private func updateItemsAttributes(for configuration: HeroConfiguration, itemIds: [HeroItemType: UUID?]) {
        Task {
            let updateAttributes = await attributeService.getAllItemsAttrbutes(for: itemIds)
            configuration.itemsAttributes = updateAttributes
        }
    }
    
    private func updateHeroConfiguration(for heroType: HeroType, itemType: HeroItemType, itemId: UUID?, blockingTwoHandsWeaponId: UUID?) {
        let configuration = heroType == .player ? playerHeroConfiguration : botHeroConfiguration
        
        if itemType == .weapons {
            configuration.blockingTwoHandsWeaponId = blockingTwoHandsWeaponId
            if blockingTwoHandsWeaponId != nil {
                configuration.itemIds[.shields] = nil
            }
        }
        
        if itemType == .shields && configuration.blockingTwoHandsWeaponId != nil {
            configuration.itemIds[.weapons] = nil
            configuration.blockingTwoHandsWeaponId = nil
        }
        
        configuration.itemIds[itemType] = itemId
    }
    
    private func getCurrentItemId(for hero: HeroType, heroItemType: HeroItemType) -> UUID? {
        let configuration = hero == .player ? playerHeroConfiguration : botHeroConfiguration
        return configuration.itemIds[heroItemType] ?? nil
    }
}
