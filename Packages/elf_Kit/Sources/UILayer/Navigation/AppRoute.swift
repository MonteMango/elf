//
//  AppRoute.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 12.11.25.
//

import Foundation

// MARK: - Navigation Routes

/// Application navigation routes
public enum AppRoute: Route {

    case mainMenu

    case battleSetup
    case battleFight(user: HeroConfiguration, enemy: HeroConfiguration)

    case selectHeroItem(
        heroType: HeroType,
        heroItemType: HeroItemType,
        currentItemId: UUID?,
        onItemSelected: (UUID?) -> Void
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
        case (.selectHeroItem(let lType, let lItem, let lId, _),
              .selectHeroItem(let rType, let rItem, let rId, _)):
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
        case .selectHeroItem(let heroType, let heroItemType, let currentItemId, _):
            hasher.combine("selectHeroItem")
            hasher.combine(heroType)
            hasher.combine(heroItemType)
            hasher.combine(currentItemId)
        }
    }
}
