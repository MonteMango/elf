//
//  EmptyItemCell.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 14.11.25.
//

import elf_SwiftUI
import SwiftUI

internal struct EmptyItemCell: View {
    let isSelected: Bool

    var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        // Empty placeholder
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 150, height: 240)

            Image(systemName: "xmark")
                .font(.system(size: 60))
                .foregroundStyle(.white.opacity(0.5))
        }
        .overlay(alignment: .top) {
            // Label overlay on top
            Text("Unequip")
                .font(.caption)
                .foregroundStyle(.white)
                .lineLimit(1)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 4)
                .padding(.top, 8)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        colors: [Color.black.opacity(0.6), Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 8,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 8
                    )
                )
        }
        .elfSelectionBorder(isSelected, cornerRadius: 8)
        .shadow(color: isSelected ? Color.blue.opacity(0.5) : Color.clear, radius: 8)
    }
}
