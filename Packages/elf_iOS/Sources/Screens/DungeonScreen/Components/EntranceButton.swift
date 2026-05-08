//
//  EntranceButton.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_SwiftUI
import SwiftUI

/// Primary action of the Dungeon Overview.
struct EntranceButton: View {
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button("Entrance", action: action)
            .buttonStyle(.elfPrimary(isEnabled: isEnabled))
            .disabled(!isEnabled)
    }
}
