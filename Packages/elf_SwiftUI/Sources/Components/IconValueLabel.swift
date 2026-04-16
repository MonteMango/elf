//
//  IconValueLabel.swift
//  elf_SwiftUI
//
//  Created by Vitalii Lytvynov
//

import SwiftUI

public struct IconValueLabel: View {

    // MARK: - Properties

    let icon: String
    let value: Int
    let color: Color

    // MARK: - Init

    public init(icon: String, value: Int, color: Color) {
        self.icon = icon
        self.value = value
        self.color = color
    }

    // MARK: - Body

    public var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        HStack(spacing: 2) {
            Image(systemName: icon)
                .font(ElfFonts.Component.iconValue)
                .foregroundStyle(color)
            Text("\(value)")
                .font(ElfFonts.Component.iconValue)
                .foregroundStyle(color)
        }
    }
}

#Preview {
    HStack(spacing: 10) {
        IconValueLabel(icon: "heart.fill", value: 83, color: .red)
        IconValueLabel(icon: "sparkles", value: 24, color: .blue)
        IconValueLabel(icon: "crown.fill", value: 148, color: .orange)
    }
    .padding()
    .background(Color.white)
}
