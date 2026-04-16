//
//  StatisticsRow.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 19.11.25.
//

import SwiftUI

internal struct StatisticsRow: View {
    let title: String
    let bot1Value: String
    let bot2Value: String

    internal var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.gray)

            Spacer()

            HStack(spacing: 32) {
                botValueView(label: "Bot1", value: bot1Value)
                botValueView(label: "Bot2", value: bot2Value)
            }
        }
        .padding(.horizontal)
    }

    private func botValueView(label: String, value: String) -> some View {
        VStack(alignment: .trailing) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.gray)
            Text(value)
                .font(.headline)
                .foregroundStyle(.white)
        }
    }
}
