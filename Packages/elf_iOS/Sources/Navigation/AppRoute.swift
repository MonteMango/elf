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
internal enum AppRoute {

    case mainMenu
    case characterCreation
    case gameSession(GameID, playTime: TimeInterval)
    case calendar
    case hunt
    case farm
    case farmActivity(FarmActivity)

    case craft
    case questList
    case quest(QuestID, ownerImageName: String)

    case battleSetup
    case battleFight(Battle)
    case autoBattleResult(Battle)
    case multiBattleResult(Battle)

    case dungeon(dungeonId: DungeonID, allyIds: [ElfID])
}

// MARK: - Hashable

extension AppRoute: Hashable {

    internal static func == (lhs: AppRoute, rhs: AppRoute) -> Bool {
        switch (lhs, rhs) {
        case (.mainMenu, .mainMenu),
             (.characterCreation, .characterCreation),
             (.calendar, .calendar),
             (.hunt, .hunt),
             (.farm, .farm),
             (.craft, .craft),
             (.questList, .questList),
             (.battleSetup, .battleSetup):
            return true
        case (.gameSession(let lhsId, _), .gameSession(let rhsId, _)):
            return lhsId == rhsId
        case (.quest(let lhsId, _), .quest(let rhsId, _)):
            return lhsId == rhsId
        case (.farmActivity(let lhs), .farmActivity(let rhs)):
            return lhs == rhs
        case (.battleFight(let lhsBattle), .battleFight(let rhsBattle)),
             (.autoBattleResult(let lhsBattle), .autoBattleResult(let rhsBattle)),
             (.multiBattleResult(let lhsBattle), .multiBattleResult(let rhsBattle)):
            return lhsBattle.id == rhsBattle.id
        case (.dungeon(let lhsId, let lhsAllies), .dungeon(let rhsId, let rhsAllies)):
            return lhsId == rhsId && lhsAllies == rhsAllies
        default:
            return false
        }
    }

    internal func hash(into hasher: inout Hasher) {
        switch self {
        case .mainMenu:
            hasher.combine("mainMenu")
        case .characterCreation:
            hasher.combine("characterCreation")
        case .gameSession(let gameId, _):
            hasher.combine("gameSession")
            hasher.combine(gameId)
        case .calendar:
            hasher.combine("calendar")
        case .hunt:
            hasher.combine("hunt")
        case .farm:
            hasher.combine("farm")
        case .craft:
            hasher.combine("craft")
        case .questList:
            hasher.combine("questList")
        case .quest(let ownerId, _):
            hasher.combine("quest")
            hasher.combine(ownerId)
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
        case .dungeon(let dungeonId, let allyIds):
            hasher.combine("dungeon")
            hasher.combine(dungeonId)
            hasher.combine(allyIds)
        }
    }
}

// MARK: - View Mapping Extension

extension AppRoute {

    @MainActor
    @ViewBuilder
    internal func view() -> some View {
        switch self {
        case .mainMenu:
            MainMenuScreen()
        case .characterCreation:
            CharacterCreationScreen()
        case .gameSession(let gameId, _):
            SessionRouteView(expectedGameId: gameId) { GameDayScreen(session: $0) }
        case .calendar:
            SessionRouteView { session in
                CalendarScreen(calendar: session.state.calendar, currentDayNumber: session.state.currentDay.dayNumber)
            }
        case .hunt:
            SessionRouteView { HuntScreen(session: $0) }
        case .farm:
            SessionRouteView { FarmScreen(session: $0) }
        case .craft:
            SessionRouteView { CraftScreen(session: $0) }
        case .questList:
            SessionRouteView { QuestListScreen(session: $0) }
        case .quest(let questId, let ownerImageName):
            SessionRouteView { QuestScreen(questId: questId, ownerImageName: ownerImageName, session: $0) }
        case .farmActivity(let activity):
            SessionRouteView { FarmActivityScreen(activity: activity, session: $0) }
        case .battleSetup:
            BattleSetupScreen()
        case .battleFight(let battle):
            BattleFightRouteView(battle: battle)
        case .autoBattleResult(let battle):
            AutoBattleResultScreen(battle: battle)
        case .multiBattleResult(let battle):
            MultiBattleResultScreen(battle: battle)
        case .dungeon:
            DungeonRouteView()
        }
    }
}
