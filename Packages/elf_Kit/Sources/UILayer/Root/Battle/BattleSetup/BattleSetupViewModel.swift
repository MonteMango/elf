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
    
    private var cancellables = Set<AnyCancellable>()
    
    public init(
        rootViewStateDelegate: AnyViewStateDelegate<RootViewState>,
        battleViewStateDelegate: AnyViewStateDelegate<BattleViewState>) {
            self.rootViewStateDelegate = rootViewStateDelegate
            self.battleViewStateDelegate = battleViewStateDelegate
        }
    
    @Published public private(set) var viewState: RootViewState = .menu
    @Published public private(set) var playerHeroConfiguration = HeroConfiguration()
    @Published public private(set) var botHeroConfiguration = HeroConfiguration()
    
    public var selectHeroItemViewModel: SelectHeroItemViewModel? {
        didSet {
            cancellables.removeAll()
            guard let selectHeroItemViewModel = self.selectHeroItemViewModel else { return }
            selectHeroItemViewModel
                .selectedHeroItem
                .sink { [weak self] heroType, heroItemType, itemId in
                    self?.updateHeroConfiguration(for: heroType, itemType: heroItemType, itemId: itemId)
                }
                .store(in: &cancellables)
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
    
    private func updateHeroConfiguration(for heroType: HeroType, itemType: HeroItemType, itemId: UUID?) {
        switch heroType {
        case .player:
            updateHeroConfiguration(&playerHeroConfiguration, itemType: itemType, itemId: itemId)
        case .bot:
            updateHeroConfiguration(&botHeroConfiguration, itemType: itemType, itemId: itemId)
        }
    }
    
    private func updateHeroConfiguration(_ configuration: inout HeroConfiguration, itemType: HeroItemType, itemId: UUID?) {
        switch itemType {
        case .helmet:
            configuration.helmetId = itemId
        case .gloves:
            configuration.glovesId = itemId
        case .shoes:
            configuration.shoesId = itemId
        case .upperBody:
            configuration.upperBodyId = itemId
        case .bottomBody:
            configuration.bottomBodyId = itemId
        case .shirt:
            configuration.shirtId = itemId
        case .ring:
            configuration.ringId = itemId
        case .necklace:
            configuration.necklaceId = itemId
        case .earrings:
            configuration.earringsId = itemId
        case .weaponPrimary:
            configuration.weaponPrimaryId = itemId
        case .weaponSecondary:
            configuration.weaponSecondaryId = itemId
        }
    }
    
    private func getCurrentItemId(for hero: HeroType, heroItemType: HeroItemType) -> UUID? {
        let configuration: HeroConfiguration
        switch hero {
        case .player:
            configuration = playerHeroConfiguration
        case .bot:
            configuration = botHeroConfiguration
        }
        
        switch heroItemType {
        case .helmet:
            return configuration.helmetId
        case .gloves:
            return configuration.glovesId
        case .shoes:
            return configuration.shoesId
        case .upperBody:
            return configuration.upperBodyId
        case .bottomBody:
            return configuration.bottomBodyId
        case .shirt:
            return configuration.shirtId
        case .ring:
            return configuration.ringId
        case .necklace:
            return configuration.necklaceId
        case .earrings:
            return configuration.earringsId
        case .weaponPrimary:
            return configuration.weaponPrimaryId
        case .weaponSecondary:
            return configuration.weaponSecondaryId
        }
    }
}

public struct HeroConfiguration {
    public var fightStyle: FightStyle? = nil
    
    public var level: Int16 = 1
    
    public var endurance: Int16? = nil
    public var intelligent: Int16? = nil
    
    public var agility: Int16? = nil
    public var strength: Int16? = nil
    public var power: Int16? = nil
    public var instinct: Int16? = nil
    
    public var helmetId: UUID? = nil
    public var glovesId: UUID? = nil
    public var shoesId: UUID? = nil
    
    public var upperBodyId: UUID? = nil
    public var bottomBodyId: UUID? = nil
    public var shirtId: UUID? = nil
    
    public var ringId: UUID? = nil
    public var necklaceId: UUID? = nil
    public var earringsId: UUID? = nil
    
    public var weaponPrimaryId: UUID? = nil
    public var weaponSecondaryId: UUID? = nil
}

public enum FightStyle {
    case crit
    case dodge
    case def
}

public enum HeroItemType {
    case helmet
    case gloves
    case shoes
    case weaponPrimary
    case weaponSecondary
    case upperBody
    case bottomBody
    case shirt
    case ring
    case necklace
    case earrings
}

public enum HeroType {
    case player
    case bot
}
