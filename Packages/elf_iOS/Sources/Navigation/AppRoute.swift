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
    case gameSession(Game, playTime: TimeInterval)
    case calendar(calendar: [GameDay], currentDayNumber: Int)
    case hunt
    case farm
    case farmActivity(FarmActivity)

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
        case (.gameSession(let lhsGame, _), .gameSession(let rhsGame, _)):
            return lhsGame.id == rhsGame.id
        case (.calendar(let lhsCalendar, let lhsDay), .calendar(let rhsCalendar, let rhsDay)):
            return lhsCalendar.count == rhsCalendar.count && lhsDay == rhsDay
        case (.hunt, .hunt):
            return true
        case (.farm, .farm):
            return true
        case (.farmActivity(let lhs), .farmActivity(let rhs)):
            return lhs == rhs
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
        case .gameSession(let game, _):
            hasher.combine("gameSession")
            hasher.combine(game.id)
        case .calendar(_, let currentDayNumber):
            hasher.combine("calendar")
            hasher.combine(currentDayNumber)
        case .hunt:
            hasher.combine("hunt")
        case .farm:
            hasher.combine("farm")
        case .farmActivity(let activity):
            hasher.combine("farmActivity")
            hasher.combine(activity.id)
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
        case .gameSession(let game, let playTime):
            GameDayScreen(game: game, playTime: playTime)
        case .calendar(let calendar, let currentDayNumber):
            CalendarScreen(calendar: calendar, currentDayNumber: currentDayNumber)
        case .hunt:
            HuntScreen()
        case .farm:
            FarmScreen()
        case .farmActivity(let activity):
            FarmActivityScreen(activity: activity)
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
