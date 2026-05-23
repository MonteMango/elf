//
//  MonstersPlaceholder.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_SwiftUI
import SwiftUI

/// Stand-in for the future expected-monsters preview (3 monster cells).
/// Same visual treatment as `MiniMapPlaceholder` so the screen reads as a
/// unified set of WIP areas while real content is being built.
struct MonstersPlaceholder: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: ElfCornerRadius.medium)
                .fill(Color.gray.opacity(0.4))

            Text("Monsters")
                .font(ElfFonts.caption)
                .fontWeight(.semibold)
                .foregroundStyle(ElfColors.Text.primaryLight)
        }
    }
}
