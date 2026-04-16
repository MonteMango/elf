//
//  PocketsView.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 28.11.25.
//

import elf_SwiftUI
import SwiftUI

struct PocketsView: View {
    let onPocketTapped: (Int) -> Void

    var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        HStack(spacing: ElfSpacing.button) {
            ForEach(0..<4, id: \.self) { index in
                pocketSlot(index: index)
            }
        }
    }

    @ViewBuilder
    private func pocketSlot(index: Int) -> some View {
        Button {
            onPocketTapped(index)
        } label: {
            Circle()
                .fill(ElfColors.Interactive.slotBackground)
                .frame(
                    width: ElfSizing.GameDay.pocketSize,
                    height: ElfSizing.GameDay.pocketSize
                )
                .overlay(
                    Circle()
                        .stroke(ElfColors.Interactive.border, lineWidth: 1)
                )
        }
    }
}

#Preview {
    PocketsView(onPocketTapped: { _ in })
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
}
