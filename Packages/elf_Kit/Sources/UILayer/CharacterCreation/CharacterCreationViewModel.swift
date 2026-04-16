//
//  CharacterCreationViewModel.swift
//  elf_Kit
//
//  Created by Claude on 23.11.25.
//

import Foundation

@MainActor
@Observable
public final class CharacterCreationViewModel {

    // MARK: - Dependencies

    private let attributeService: any AttributeService
    private let nameValidator: any CharacterNameValidator
    private let characterBuilder: any CharacterBuilder
    private let fightStyleDescriptionService: any FightStyleDescriptionService
    private let nameSuggestionService: any CharacterNameSuggestionService
    private let gameInitializationService: any GameInitializationService

    // MARK: - Stage State

    /// Current stage
    public var currentStage: CharacterCreationStage = .selectAppearance

    /// Set of visited stages
    public var visitedStages: Set<CharacterCreationStage> = [.selectAppearance]

    /// Whether character creation is finalized
    public var isCharacterReady: Bool = false

    // MARK: - Stage 1: Appearance

    /// Selected appearance
    public var selectedAppearance: CharacterAppearance? {
        didSet {
            if let appearance = selectedAppearance {
                characterBuilder.setAppearance(appearance)
            }
        }
    }

    // MARK: - Stage 2: Name

    /// Character name input
    public var characterName: String = "" {
        didSet {
            characterBuilder.setName(characterName)
        }
    }

    /// Name validation error message
    public var nameValidationError: String?

    // MARK: - Stage 3: Fight Style

    /// Selected fight style
    public var selectedFightStyle: FightStyle? = .dodge {
        didSet {
            if let style = selectedFightStyle {
                characterBuilder.setFightStyle(style)
                loadFightStyleDescriptions(for: style)
            }
        }
    }

    /// Fight style description
    public var fightStyleDescription: String?

    /// Fight style attributes description
    public var fightStyleAttributesDescription: String?

    // MARK: - Stage 4: Summary & Final

    /// Fight style base attributes
    public var fightStyleAttributes: HeroAttributes?

    /// Random level attributes (generated on Ready)
    public var randomLevelAttributes: HeroAttributes?

    /// Created character (available after Start)
    public var createdCharacter: PlayerCharacter?

    /// Created game with houses (available after finalize)
    public var createdGame: Game?

    // MARK: - Computed Properties

    /// Check if can proceed to next stage
    public var canProceedToNextStage: Bool {
        switch currentStage {
        case .selectAppearance:
            return selectedAppearance != nil
        case .enterName:
            return !characterName.isEmpty && nameValidationError == nil
        case .selectFightStyle:
            return selectedFightStyle != nil
        case .reviewAndFinalize:
            return true
        }
    }

    // MARK: - Initialization

    public init(
        attributeService: any AttributeService,
        nameValidator: any CharacterNameValidator,
        characterBuilder: any CharacterBuilder,
        fightStyleDescriptionService: any FightStyleDescriptionService,
        nameSuggestionService: any CharacterNameSuggestionService,
        gameInitializationService: any GameInitializationService
    ) {
        self.attributeService = attributeService
        self.nameValidator = nameValidator
        self.characterBuilder = characterBuilder
        self.fightStyleDescriptionService = fightStyleDescriptionService
        self.nameSuggestionService = nameSuggestionService
        self.gameInitializationService = gameInitializationService

        if let style = selectedFightStyle {
            characterBuilder.setFightStyle(style)
        }
    }

    // MARK: - Stage Navigation

    /// Move to next stage
    public func goToNextStage() {
        guard canProceedToNextStage else { return }

        guard let nextStage = currentStage.next else { return }

        currentStage = nextStage
        visitedStages.insert(currentStage)

        // Load fight style attributes when entering review stage
        if currentStage == .reviewAndFinalize && fightStyleAttributes == nil {
            loadFightStyleAttributes()
        }
    }

    /// Go to specific stage (only if visited)
    public func goToStage(_ stage: CharacterCreationStage) {
        guard visitedStages.contains(stage) else { return }
        currentStage = stage
    }

    // MARK: - Stage 2: Name Actions

    /// Generate random name
    public func generateRandomName() {
        characterName = nameSuggestionService.generateRandomName()
        validateName()
    }

    /// Validate character name
    public func validateName() {
        let result = nameValidator.validate(characterName)
        nameValidationError = result.errorMessage
    }

    // MARK: - Stage 3: Fight Style Actions

    /// Load fight style descriptions for selected style
    public func loadFightStyleDescriptions(for style: FightStyle) {
        fightStyleDescription = fightStyleDescriptionService.getDescription(for: style)
        fightStyleAttributesDescription = fightStyleDescriptionService.getAttributeBonusDescription(for: style)
    }

    // MARK: - Stage 4: Final Actions

    /// Load fight style attributes
    private func loadFightStyleAttributes() {
        guard let style = selectedFightStyle else { return }
        let level = GameMechanicsConstants.startingLevel
        fightStyleAttributes = attributeService.getAllFightStyleAttributes(for: style, at: level)
    }

    /// Generate random attributes and finalize character
    public func finalizeCharacter() async {
        guard selectedFightStyle != nil,
              selectedAppearance != nil,
              fightStyleAttributes != nil else { return }

        randomLevelAttributes = attributeService.getRandomLevelAttributes()

        guard let character = createCharacter() else { return }

        do {
            createdGame = try await gameInitializationService.createNewGame(
                playerCharacter: character
            )
            isCharacterReady = true
        } catch {
            print("Failed to create game: \(error)")
        }
    }

    /// Create and return the final character using builder
    public func createCharacter() -> PlayerCharacter? {
        guard let fightAttrs = fightStyleAttributes,
              let randomAttrs = randomLevelAttributes else {
            print("❌ createCharacter failed: missing attributes")
            return nil
        }

        do {
            let character = try characterBuilder.build(
                fightStyleAttributes: fightAttrs,
                randomLevelAttributes: randomAttrs
            )
            createdCharacter = character
            print("✅ Character created: \(character.name)")
            return character
        } catch {
            print("❌ createCharacter failed: \(error)")
            return nil
        }
    }

}
