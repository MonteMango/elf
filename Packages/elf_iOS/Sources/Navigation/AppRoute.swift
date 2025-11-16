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
    case battleFight(Battle)
}

// MARK: - Hashable

extension AppRoute: Hashable {

    public static func == (lhs: AppRoute, rhs: AppRoute) -> Bool {
        switch (lhs, rhs) {
        case (.mainMenu, .mainMenu):
            return true
        case (.battleSetup, .battleSetup):
            return true
        case (.battleFight(let lhsBattle), .battleFight(let rhsBattle)):
            return lhsBattle.id == rhsBattle.id
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
        case .battleFight(let battle):
            hasher.combine("battleFight")
            hasher.combine(battle.id)
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
        case .battleFight(let battle):
            BattleFightScreen(battle: battle)
        }
    }
}
