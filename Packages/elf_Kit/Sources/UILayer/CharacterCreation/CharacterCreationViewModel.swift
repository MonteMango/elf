//
//  CharacterCreationViewModel.swift
//  elf_Kit
//
//  Created by Claude on 23.11.25.
//

import Foundation

@Observable
@MainActor
public final class CharacterCreationViewModel {

    // MARK: - Dependencies

    private let attributeService: AttributeService
    private let nameValidator: CharacterNameValidator
    private let characterBuilder: CharacterBuilder
    private let fightStyleDescriptionService: FightStyleDescriptionService
    private let nameSuggestionService: CharacterNameSuggestionService
    private let houseService: HouseService
    private let elfInfoFactory: ElfInfoFactory

    // MARK: - Stage State

    /// Current stage
    public var currentStage: CharacterCreationStage = .selectAppearance

    /// Set of visited stages
    public var visitedStages: Set<CharacterCreationStage> = [.selectAppearance]

    /// Whether character creation is finalized
    public var isCharacterReady: Bool = false

    /// Loading state for attributes
    public var isLoadingAttributes: Bool = false

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
            }
        }
    }

    // MARK: - Stage 4: Summary & Final

    /// Fight style base attributes
    public var fightStyleAttributes: HeroAttributes?

    /// Random level attributes (generated on Ready)
    public var randomLevelAttributes: HeroAttributes?

    /// Created character (available after Start)
    public var createdCharacter: PlayerCharacter?

    /// Created game with houses (available after finalize)
    public var createdGame: Game?

    // MARK: - Private State

    /// Task for loading attributes
    private var attributeLoadingTask: Task<Void, Never>?

    // MARK: - Computed Properties

    /// Check if can proceed to next stage
    public var canProceedToNextStage: Bool {
        if isLoadingAttributes {
            return false
        }

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
        attributeService: AttributeService,
        nameValidator: CharacterNameValidator,
        characterBuilder: CharacterBuilder,
        fightStyleDescriptionService: FightStyleDescriptionService,
        nameSuggestionService: CharacterNameSuggestionService,
        houseService: HouseService,
        elfInfoFactory: ElfInfoFactory
    ) {
        self.attributeService = attributeService
        self.nameValidator = nameValidator
        self.characterBuilder = characterBuilder
        self.fightStyleDescriptionService = fightStyleDescriptionService
        self.nameSuggestionService = nameSuggestionService
        self.houseService = houseService
        self.elfInfoFactory = elfInfoFactory

        // Set default fight style in builder (didSet doesn't trigger on initial value)
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

    /// Get description for fight style
    public func getFightStyleDescription(_ style: FightStyle) -> String {
        return fightStyleDescriptionService.getDescription(for: style)
    }

    /// Get base attributes description for fight style
    public func getFightStyleAttributesDescription(_ style: FightStyle) -> String {
        return fightStyleDescriptionService.getAttributeBonusDescription(for: style)
    }

    // MARK: - Stage 4: Final Actions

    /// Load fight style attributes
    private func loadFightStyleAttributes() {
        // Cancel previous task if any
        attributeLoadingTask?.cancel()

        guard let style = selectedFightStyle else { return }

        attributeLoadingTask = Task { @MainActor in
            isLoadingAttributes = true
            defer { isLoadingAttributes = false }

            fightStyleAttributes = await attributeService.getAllFightStyleAttributes(
                for: style,
                at: GameMechanicsConstants.startingLevel
            )
        }
    }

    /// Generate random attributes and finalize character
    public func finalizeCharacter() async {
        guard selectedFightStyle != nil,
              selectedAppearance != nil,
              fightStyleAttributes != nil else { return }

        // Generate random attributes
        randomLevelAttributes = await attributeService.getRandomLevelAttributes()

        // Create character and game with houses
        if let character = createCharacter() {
            let playerElfInfo = elfInfoFactory.create(from: character)
            let (houses, houseIndex, memberIndex) = await houseService.createAllHouses(
                playerElfInfo: playerElfInfo
            )

            let gameState = GameState(
                currentDay: GameDay(dayNumber: 1, dayType: .normal),
                currentActionPoints: 100,
                maxActionPoints: 100,
                upcomingDays: [
                    GameDay(dayNumber: 2, dayType: .dungeon),
                    GameDay(dayNumber: 3, dayType: .normal),
                    GameDay(dayNumber: 4, dayType: .houseWar)
                ]
            )

            createdGame = Game(
                houses: houses,
                gameState: gameState,
                playerHouseIndex: houseIndex,
                playerMemberIndex: memberIndex
            )
        }

        isCharacterReady = true
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

    /// Start the game with created character
    public func startGame() {
        _ = createCharacter()
        // Navigation will be handled by the view
    }
}
