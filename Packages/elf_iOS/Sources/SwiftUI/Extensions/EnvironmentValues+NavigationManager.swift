//
//  EnvironmentValues+NavigationManager.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 12.11.25.
//

import SwiftUI

private struct NavigationManagerKey: EnvironmentKey {
    static let defaultValue: AppNavigationManager = AppNavigationManager.shared
}

public extension EnvironmentValues {
    var navigationManager: AppNavigationManager {
        get { self[NavigationManagerKey.self] }
        set { self[NavigationManagerKey.self] = newValue }
    }
}
