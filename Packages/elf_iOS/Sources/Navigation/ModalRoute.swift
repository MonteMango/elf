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
public enum ModalRoute: Identifiable {

    case battleResult(ManualBattleResult)

    // MARK: - Identifiable

    public var id: String {
        switch self {
        case .battleResult:
            return "battleResult"
        }
    }
}

// MARK: - View Mapping Extension

extension ModalRoute {

    @MainActor
    @ViewBuilder
    public func view() -> some View {
        switch self {
        case .battleResult(let result):
            BattleResultScreen(result: result)
        }
    }
}
