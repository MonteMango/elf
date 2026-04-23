//
//  MainMenuScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 10.11.25.
//

import elf_Kit
import SwiftUI

struct MainMenuScreen: View {
    var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        MainMenuScreenContent(viewModel: MainMenuViewModel())
    }
}
