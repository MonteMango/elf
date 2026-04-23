//
//  CharacterCreationScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 23.11.25.
//

import elf_Kit
import SwiftUI

struct CharacterCreationScreen: View {
    var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        CharacterCreationScreenContent(viewModel: CharacterCreationViewModel())
    }
}
