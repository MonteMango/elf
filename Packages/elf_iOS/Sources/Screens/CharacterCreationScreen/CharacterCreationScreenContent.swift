//
//  CharacterCreationScreenContent.swift
//  elf_iOS
//
//  Created by Claude on 23.11.25.
//

import elf_Kit
import elf_SwiftUI
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

            // Content area with stage views
            GeometryReader { outerGeometry in
                let safeArea = outerGeometry.safeAreaInsets
                let fullHeight = outerGeometry.size.height

                GeometryReader { geometry in
                    let fullWidth = geometry.size.width

                    ScrollView(.horizontal) {
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
                                    await viewModel.generateRandomName()
                                },
                                onNameChanged: {
                                    await viewModel.validateName()
                                },
                                isTextFieldFocused: $isTextFieldFocused
                            )
                            .frame(width: fullWidth, height: fullHeight)
                            .id(2)

                            FightStyleSelectionView(
                                selectedFightStyle: $viewModel.selectedFightStyle,
                                safeAreaInsets: safeArea,
                                fightStyleDescription: viewModel.fightStyleDescription,
                                fightStyleAttributesDescription: viewModel.fightStyleAttributesDescription
                            )
                            .task {
                                if let style = viewModel.selectedFightStyle {
                                    await viewModel.loadFightStyleDescriptions(for: style)
                                }
                            }
                            .frame(width: fullWidth, height: fullHeight)
                            .id(3)

                            CharacterSummaryView(
                                appearance: viewModel.selectedAppearance,
                                name: viewModel.characterName,
                                fightStyle: viewModel.selectedFightStyle,
                                fightStyleAttributes: viewModel.fightStyleAttributes,
                                randomAttributes: viewModel.randomLevelAttributes,
                                isCharacterReady: viewModel.isCharacterReady,
                                assignedHouse: viewModel.createdGame?.playerHouse,
                                safeAreaInsets: safeArea
                            )
                            .frame(width: fullWidth, height: fullHeight)
                            .id(4)
                        }
                    }
                    .scrollIndicators(.hidden)
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
                    if let game = viewModel.createdGame {
                        router.navigate(to: .gameSession(game, playTime: 0), removingPrevious: 1)
                    }
                }
            }) {
                Text(buttonText)
            }
            .buttonStyle(.elfPrimary(isEnabled: isButtonEnabled))
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

    private var isButtonEnabled: Bool {
        (viewModel.canProceedToNextStage || viewModel.isCharacterReady)
        && !viewModel.isLoadingAttributes
    }
}

#Preview {
    @Previewable @State var gameContainer: ElfGameContainer?
    @Previewable @State var router = AppRouter()

    if let gameContainer {
        NavigationStack(path: $router.navigationPath) {
            CharacterCreationScreenContent(
                viewModel: gameContainer.makeCharacterCreationViewModel()
            )
            .environment(router)
            .environment(gameContainer)
        }
    } else {
        ProgressView()
            .task {
                let container = await ElfGameContainer()
                gameContainer = container
            }
    }
}
