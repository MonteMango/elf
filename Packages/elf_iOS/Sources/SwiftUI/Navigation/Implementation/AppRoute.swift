//
//  AppRoute.swift
//  elf_SwiftUI
//
//  Created by Vitalii Lytvynov on 12.11.25.
//

import SwiftUI

// MARK: - Navigation Routes
public enum AppRoute: Route {
    
    case mainMenu
    
    case battleSetup
    case battleFight
    
    @ViewBuilder
    public func view() -> some View {
        switch self {
        case .mainMenu:
            MainMenuScreen()
        case .battleSetup:
            BattleSetupScreen()
        case .battleFight:
            BattleFightScreen()
        }
    }
}
