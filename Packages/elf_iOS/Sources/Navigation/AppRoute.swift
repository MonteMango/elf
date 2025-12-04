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
    case characterCreation
    case gameDay(Game)

    case battleSetup
    case battleFight(Battle)
    case autoBattleResult(Battle)
    case multiBattleResult(Battle)
}

// MARK: - Hashable

extension AppRoute: Hashable {

    public static func == (lhs: AppRoute, rhs: AppRoute) -> Bool {
        switch (lhs, rhs) {
        case (.mainMenu, .mainMenu):
            return true
        case (.characterCreation, .characterCreation):
            return true
        case (.gameDay(let lhsGame), .gameDay(let rhsGame)):
            return lhsGame.id == rhsGame.id
        case (.battleSetup, .battleSetup):
            return true
        case (.battleFight(let lhsBattle), .battleFight(let rhsBattle)):
            return lhsBattle.id == rhsBattle.id
        case (.autoBattleResult(let lhsBattle), .autoBattleResult(let rhsBattle)):
            return lhsBattle.id == rhsBattle.id
        case (.multiBattleResult(let lhsBattle), .multiBattleResult(let rhsBattle)):
            return lhsBattle.id == rhsBattle.id
        default:
            return false
        }
    }

    public func hash(into hasher: inout Hasher) {
        switch self {
        case .mainMenu:
            hasher.combine("mainMenu")
        case .characterCreation:
            hasher.combine("characterCreation")
        case .gameDay(let game):
            hasher.combine("gameDay")
            hasher.combine(game.id)
        case .battleSetup:
            hasher.combine("battleSetup")
        case .battleFight(let battle):
            hasher.combine("battleFight")
            hasher.combine(battle.id)
        case .autoBattleResult(let battle):
            hasher.combine("autoBattleResult")
            hasher.combine(battle.id)
        case .multiBattleResult(let battle):
            hasher.combine("multiBattleResult")
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
        case .characterCreation:
            CharacterCreationScreen()
        case .gameDay(let game):
            GameDayScreen(game: game)
        case .battleSetup:
            BattleSetupScreen()
        case .battleFight(let battle):
            BattleFightScreen(battle: battle)
        case .autoBattleResult(let battle):
            AutoBattleResultScreen(battle: battle)
        case .multiBattleResult(let battle):
            MultiBattleResultScreen(battle: battle)
        }
    }
}
