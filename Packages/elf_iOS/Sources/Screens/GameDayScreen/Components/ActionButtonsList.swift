//
//  ActionButtonsList.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 28.11.25.
//

import elf_Kit
import elf_SwiftUI
import SwiftUI

struct ActionButtonsList: View {
    let actions: [ActionType]
    let onAction: (ActionType) -> Void

    var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        VStack(spacing: ElfSpacing.button) {
            ForEach(actions, id: \.self) { action in
                actionButton(for: action)
            }
        }
    }

    @ViewBuilder
    private func actionButton(for action: ActionType) -> some View {
        Button {
            onAction(action)
        } label: {
            Text(action.rawValue)
        }
        .buttonStyle(.elfPrimary)
    }
}

#Preview {
    ActionButtonsList(actions: ActionType.allCases, onAction: { _ in })
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
}
