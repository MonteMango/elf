//
//  ModalRoute.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 12.12.25.
//

import elf_Kit
import SwiftUI

// MARK: - Modal Routes

/// Modal presentation routes (displayed as overlay on top of navigation stack)
internal enum ModalRoute: Identifiable {

    case battleResult(ManualBattleResult)
    case fishingResult(FishingResult)
    case foragingResult(ForagingResult)
    case miningResult(MiningResult)

    // MARK: - Identifiable

    internal var id: String {
        switch self {
        case .battleResult:
            return "battleResult"
        case .fishingResult:
            return "fishingResult"
        case .foragingResult:
            return "foragingResult"
        case .miningResult:
            return "miningResult"
        }
    }
}

// MARK: - View Mapping Extension

extension ModalRoute {

    @MainActor
    @ViewBuilder
    internal func view() -> some View {
        switch self {
        case .battleResult(let result):
            BattleResultScreen(result: result)
        case .fishingResult(let result):
            FishingResultScreen(result: result)
        case .foragingResult(let result):
            ForagingResultScreen(result: result)
        case .miningResult(let result):
            MiningResultScreen(result: result)
        }
    }
}
