//
//  PocketsView.swift
//  elf_SwiftUI
//
//  Created by Vitalii Lytvynov
//

import SwiftUI

public struct PocketsView: View {

    // MARK: - Properties

    let onPocketTapped: (Int) -> Void

    // MARK: - Init

    public init(onPocketTapped: @escaping (Int) -> Void) {
        self.onPocketTapped = onPocketTapped
    }

    // MARK: - Body

    public var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        HStack(spacing: ElfSpacing.button) {
            ForEach(0..<4, id: \.self) { index in
                pocketSlot(index: index)
            }
        }
    }

    // MARK: - Subviews

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
