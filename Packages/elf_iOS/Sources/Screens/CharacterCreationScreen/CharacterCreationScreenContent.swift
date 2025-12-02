//
//  CharacterCreationScreenContent.swift
//  elf_iOS
//
//  Created by Claude on 23.11.25.
//

import elf_Kit
import SwiftUI

struct CharacterCreationScreenContent: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel: CharacterCreationViewModel
    @FocusState private var isTextFieldFocused: Bool

    init(viewModel: CharacterCreationViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Stage indicator (hidden when character is ready)
            if !viewModel.isCharacterReady {
                CreateCharacterStageView(
                    currentStage: viewModel.currentStage,
                    visitedStages: viewModel.visitedStages,
                    onStageSelected: { stage in
                        viewModel.goToStage(stage)
                    },
                    onClose: {
                        router.pop()
                    }
                )
            } else {
                // Just show close button when ready
                HStack {
                    Spacer()
                    Button(action: {
                        router.pop()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.red)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color(red: 0.7, green: 0.85, blue: 0.95))
            }

            // Content area with stage views
            GeometryReader { outerGeometry in
                let safeArea = outerGeometry.safeAreaInsets
                let fullHeight = outerGeometry.size.height

                GeometryReader { geometry in
                    let fullWidth = geometry.size.width

                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 0) {
                            AppearanceSelectionView(
                                selectedAppearance: $viewModel.selectedAppearance,
                                safeAreaInsets: safeArea
                            )
                            .frame(width: fullWidth, height: fullHeight)
                            .id(1)

                            NameInputView(
                                characterName: $viewModel.characterName,
                                validationError: $viewModel.nameValidationError,
                                safeAreaInsets: safeArea,
                                onRandomName: {
                                    viewModel.generateRandomName()
                                },
                                onNameChanged: {
                                    viewModel.validateName()
                                },
                                isTextFieldFocused: $isTextFieldFocused
                            )
                            .frame(width: fullWidth, height: fullHeight)
                            .id(2)

                            FightStyleSelectionView(
                                selectedFightStyle: $viewModel.selectedFightStyle,
                                safeAreaInsets: safeArea,
                                getDescription: { style in
                                    viewModel.getFightStyleDescription(style)
                                },
                                getAttributesDescription: { style in
                                    viewModel.getFightStyleAttributesDescription(style)
                                }
                            )
                            .frame(width: fullWidth, height: fullHeight)
                            .id(3)

                            CharacterSummaryView(
                                appearance: viewModel.selectedAppearance,
                                name: viewModel.characterName,
                                fightStyle: viewModel.selectedFightStyle,
                                fightStyleAttributes: viewModel.fightStyleAttributes,
                                randomAttributes: viewModel.randomLevelAttributes,
                                isCharacterReady: viewModel.isCharacterReady,
                                safeAreaInsets: safeArea
                            )
                            .frame(width: fullWidth, height: fullHeight)
                            .id(4)
                        }
                    }
                    .scrollPosition(id: Binding(
                        get: { viewModel.currentStage.rawValue },
                        set: { if let newValue = $0, let stage = CharacterCreationStage(rawValue: newValue) {
                            viewModel.currentStage = stage
                        }}
                    ))
                    .scrollDisabled(true)
                    .scrollTargetBehavior(.paging)
                    .clipped()
                    .onChange(of: viewModel.currentStage) { _, _ in
                        isTextFieldFocused = false
                    }
                }
                .ignoresSafeArea(.all, edges: .horizontal)
            }
            .ignoresSafeArea(.keyboard)
            .background(Color.white)
        }
        .overlay(alignment: .bottomTrailing) {
            // Static Next/Ready/Start button
            Button(action: {
                if viewModel.currentStage != .reviewAndFinalize {
                    // Stages 1-3: Next
                    viewModel.goToNextStage()
                } else if !viewModel.isCharacterReady {
                    // Stage 4 before Ready: Ready
                    Task {
                        await viewModel.finalizeCharacter()
                    }
                } else {
                    // Stage 4 after Ready: Start - Navigate to game screen
                    if let character = viewModel.createdCharacter ?? viewModel.createCharacter() {
                        router.navigate(to: .gameDay(character), removingPrevious: 1)
                    }
                }
            }) {
                Text(buttonText)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 150)
                    .frame(height: 50)
                    .background(buttonBackgroundColor)
                    .cornerRadius(8)
                    .opacity(isButtonEnabled ? 1.0 : 0.6)
            }
            .disabled(!isButtonEnabled)
            .padding(.bottom, StagePadding.standard)
        }
    }

    // MARK: - Helper Computed Properties

    private var buttonText: String {
        if viewModel.currentStage != .reviewAndFinalize {
            return "Next"
        }
        return viewModel.isCharacterReady ? "Start" : "Ready"
    }

    private var buttonBackgroundColor: Color {
        if viewModel.isLoadingAttributes {
            return .gray
        }
        return (viewModel.canProceedToNextStage || viewModel.isCharacterReady) ? .orange : .gray
    }

    private var isButtonEnabled: Bool {
        (viewModel.canProceedToNextStage || viewModel.isCharacterReady)
        && !viewModel.isLoadingAttributes
    }
}

#Preview {
    @Previewable @State var router = AppRouter()
    let container = ElfAppDependencyContainer()

    NavigationStack(path: $router.navigationPath) {
        CharacterCreationScreenContent(
            viewModel: container.makeCharacterCreationViewModel()
        )
        .environment(router)
        .environment(container)
    }
}
