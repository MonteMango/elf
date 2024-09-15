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
    
    @Published public private(set) var viewState: RootViewState = .menu
    @Published public var playerHeroConfiguration = HeroConfiguration()
    @Published public var botHerConfiguration = HeroConfiguration()
    
    public init(rootViewStateDelegate: AnyViewStateDelegate<RootViewState>) {
        self.rootViewStateDelegate = rootViewStateDelegate
    }
    
    @objc
    public func closeButtonAction() {
        rootViewStateDelegate.setViewState(.menu)
    }
}

public struct HeroConfiguration {
    public var fightStyle: FightStyle? = nil
    
    public var level: Int16? = nil
    
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
    
    public var weaponFirstId: UUID? = nil
    public var weaponSecondaryId: UUID? = nil
}

public enum FightStyle {
    case crit
    case dodge
    case def
}
