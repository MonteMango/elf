//
//  AppRoute.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 12.11.25.
//

import elf_Kit
import SwiftUI

// MARK: - Navigation Routes

/// Application navigation routes
public enum AppRoute {

    case mainMenu

    case battleSetup
    case battleFight(user: HeroConfiguration, enemy: HeroConfiguration)

    case selectHeroItem(
        heroType: HeroType,
        heroItemType: HeroItemType,
        currentItemId: UUID?
    )
}

// MARK: - Hashable

extension AppRoute: Hashable {

    public static func == (lhs: AppRoute, rhs: AppRoute) -> Bool {
        switch (lhs, rhs) {
        case (.mainMenu, .mainMenu):
            return true
        case (.battleSetup, .battleSetup):
            return true
        case (.battleFight(let lUser, let lEnemy), .battleFight(let rUser, let rEnemy)):
            return ObjectIdentifier(lUser) == ObjectIdentifier(rUser) &&
                   ObjectIdentifier(lEnemy) == ObjectIdentifier(rEnemy)
        case (.selectHeroItem(let lType, let lItem, let lId),
              .selectHeroItem(let rType, let rItem, let rId)):
            return lType == rType && lItem == rItem && lId == rId
        default:
            return false
        }
    }

    public func hash(into hasher: inout Hasher) {
        switch self {
        case .mainMenu:
            hasher.combine("mainMenu")
        case .battleSetup:
            hasher.combine("battleSetup")
        case .battleFight(let user, let enemy):
            hasher.combine("battleFight")
            hasher.combine(ObjectIdentifier(user))
            hasher.combine(ObjectIdentifier(enemy))
        case .selectHeroItem(let heroType, let heroItemType, let currentItemId):
            hasher.combine("selectHeroItem")
            hasher.combine(heroType)
            hasher.combine(heroItemType)
            hasher.combine(currentItemId)
        }
    }
}

// MARK: - View Mapping Extension

extension AppRoute {

    @MainActor
    @ViewBuilder
    public func view() -> some View {
        switch self {
        case .mainMenu:
            MainMenuScreen()
        case .battleSetup:
            BattleSetupScreen()
        case .battleFight(let user, let enemy):
            BattleFightScreen(userConfiguration: user, enemyConfiguration: enemy)
        case .selectHeroItem(let heroType, let heroItemType, let currentId):
            SelectHeroItemScreen(heroType: heroType, heroItemType: heroItemType, currentItemId: currentId)
        }
    }
}
