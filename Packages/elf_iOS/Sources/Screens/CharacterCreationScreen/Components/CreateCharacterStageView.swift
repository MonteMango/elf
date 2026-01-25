//
//  CreateCharacterStageView.swift
//  elf_iOS
//
//  Created by Claude on 23.11.25.
//

import elf_Kit
import SwiftUI

/// Stage indicator view for character creation flow
struct CreateCharacterStageView: View {
    let currentStage: CharacterCreationStage
    let visitedStages: Set<CharacterCreationStage>
    let onStageSelected: (CharacterCreationStage) -> Void
    let onClose: () -> Void

    var body: some View {
        HStack {
            ForEach(CharacterCreationStage.allCases, id: \.self) { stage in
                stageButton(for: stage)
                if !stage.isLast {
                    Spacer()
                }
            }

            Spacer()

            // Close button
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .bold()
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.red)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color(red: 0.7, green: 0.85, blue: 0.95))
    }

    @ViewBuilder
    private func stageButton(for stage: CharacterCreationStage) -> some View {
        let isVisited = visitedStages.contains(stage)
        let isCurrent = stage == currentStage
        let isAccessible = isVisited

        Button(action: {
            if isAccessible {
                onStageSelected(stage)
            }
        }) {
            Text("\(stage.number)")
                .font(.title2)
                .bold()
                .foregroundStyle(stageTextColor(isVisited: isVisited, isCurrent: isCurrent))
                .frame(width: 50, height: 50)
                .background(stageBackgroundColor(isVisited: isVisited, isCurrent: isCurrent))
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(stageBorderColor(isVisited: isVisited, isCurrent: isCurrent), lineWidth: isCurrent ? 3 : 0)
                )
        }
        .disabled(!isAccessible)
    }

    private func stageTextColor(isVisited: Bool, isCurrent: Bool) -> Color {
        if isCurrent {
            return Color(red: 0.9, green: 0.3, blue: 0.4)
        } else if isVisited {
            return .white
        } else {
            return .gray
        }
    }

    private func stageBackgroundColor(isVisited: Bool, isCurrent: Bool) -> Color {
        if isCurrent {
            return Color(white: 0.85)
        } else if isVisited {
            return .green
        } else {
            return Color(white: 0.85)
        }
    }

    private func stageBorderColor(isVisited: Bool, isCurrent: Bool) -> Color {
        if isCurrent {
            return Color(red: 0.9, green: 0.3, blue: 0.4)
        }
        return .clear
    }
}

#Preview {
    VStack {
        CreateCharacterStageView(
            currentStage: .selectAppearance,
            visitedStages: [.selectAppearance],
            onStageSelected: { _ in },
            onClose: {}
        )

        CreateCharacterStageView(
            currentStage: .enterName,
            visitedStages: [.selectAppearance, .enterName],
            onStageSelected: { _ in },
            onClose: {}
        )

        CreateCharacterStageView(
            currentStage: .selectFightStyle,
            visitedStages: [.selectAppearance, .enterName, .selectFightStyle],
            onStageSelected: { _ in },
            onClose: {}
        )

        CreateCharacterStageView(
            currentStage: .reviewAndFinalize,
            visitedStages: [.selectAppearance, .enterName, .selectFightStyle, .reviewAndFinalize],
            onStageSelected: { _ in },
            onClose: {}
        )
    }
}
