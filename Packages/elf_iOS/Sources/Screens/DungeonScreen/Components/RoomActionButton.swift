//
//  RoomActionButton.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_SwiftUI
import SwiftUI

/// Primary action of a dungeon room — replaces `EntranceButton` once the squad
/// has entered. Title varies by room kind (`Fight` / `Drink`), supplied by the
/// view model.
struct RoomActionButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(title, action: action)
            .buttonStyle(.elfPrimary(isEnabled: true))
    }
}
