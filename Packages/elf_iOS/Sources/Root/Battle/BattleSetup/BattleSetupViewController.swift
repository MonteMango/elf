//
//  BattleSetupViewController.swift
//  
//
//  Created by Vitalii Lytvynov on 28.08.24.
//

import Combine
import elf_Kit
import elf_UIKit
import Foundation
import UIKit

internal final class BattleSetupViewController: NiblessViewController {
   
    // MARK: Properties
    
    private let viewModel: BattleSetupViewModel
    private let screenView: BattleSetupScreenView
    
    private var cancellables = Set<AnyCancellable>()
    
    internal init(viewModel: BattleSetupViewModel) {
        self.viewModel = viewModel
        self.screenView = BattleSetupScreenView()
        super.init()
    }
    
    internal override func loadView() {
        super.loadView()
        view = screenView
    }
    
    internal override func viewDidLoad() {
        super.viewDidLoad()
        setupBindings()
        setupActions()
    }
    
    // MARK: Bindings
    
    private func setupBindings() {
        
        bindLevel(viewModel.playerHeroConfiguration.$level, to: screenView.userLevelView)
        bindLevel(viewModel.botHeroConfiguration.$level, to: screenView.botLevelView)
        
        bindAttributes(viewModel.playerHeroConfiguration, to: screenView.userAttributesView)
        bindAttributes(viewModel.botHeroConfiguration, to: screenView.botAttributesView)
        
        bindFightStyle(screenView.userSelectFightStyleStackView.selectFightStyleRadioButtonGroup, heroType: .player)
        bindFightStyle(screenView.botSelectFightStyleStackView.selectFightStyleRadioButtonGroup, heroType: .bot)
        
        // Привязка кнопок для игрока
        bindItemButton(for: .helmet, configuration: viewModel.playerHeroConfiguration, button: screenView.userHeroItemsView.helmetItemButton)
        bindItemButton(for: .gloves, configuration: viewModel.playerHeroConfiguration, button: screenView.userHeroItemsView.glovesItemButton)
        bindItemButton(for: .shoes, configuration: viewModel.playerHeroConfiguration, button: screenView.userHeroItemsView.shoesItemButton)
        bindItemButton(for: .upperBody, configuration: viewModel.playerHeroConfiguration, button: screenView.userHeroItemsView.upperBodyItemButton)
        bindItemButton(for: .bottomBody, configuration: viewModel.playerHeroConfiguration, button: screenView.userHeroItemsView.bottomBodyItemButton)
        bindItemButton(for: .shirt, configuration: viewModel.playerHeroConfiguration, button: screenView.userHeroItemsView.shirtItemButton)
        bindItemButton(for: .ring, configuration: viewModel.playerHeroConfiguration, button: screenView.userHeroItemsView.ringItemButton)
        bindItemButton(for: .necklace, configuration: viewModel.playerHeroConfiguration, button: screenView.userHeroItemsView.necklaceItemButton)
        bindItemButton(for: .earrings, configuration: viewModel.playerHeroConfiguration, button: screenView.userHeroItemsView.earringsItemButton)
        bindItemButton(for: .weapons, configuration: viewModel.playerHeroConfiguration, button: screenView.userHeroItemsView.weaponPrimaryItemButton)
        bindItemButton(for: .shields, configuration: viewModel.playerHeroConfiguration, button: screenView.userHeroItemsView.weaponScondaryItemButton)
        
        // Привязка кнопок для бота
        bindItemButton(for: .helmet, configuration: viewModel.botHeroConfiguration, button: screenView.botHeroItemsView.helmetItemButton)
        bindItemButton(for: .gloves, configuration: viewModel.botHeroConfiguration, button: screenView.botHeroItemsView.glovesItemButton)
        bindItemButton(for: .shoes, configuration: viewModel.botHeroConfiguration, button: screenView.botHeroItemsView.shoesItemButton)
        bindItemButton(for: .upperBody, configuration: viewModel.botHeroConfiguration, button: screenView.botHeroItemsView.upperBodyItemButton)
        bindItemButton(for: .bottomBody, configuration: viewModel.botHeroConfiguration, button: screenView.botHeroItemsView.bottomBodyItemButton)
        bindItemButton(for: .shirt, configuration: viewModel.botHeroConfiguration, button: screenView.botHeroItemsView.shirtItemButton)
        bindItemButton(for: .ring, configuration: viewModel.botHeroConfiguration, button: screenView.botHeroItemsView.ringItemButton)
        bindItemButton(for: .necklace, configuration: viewModel.botHeroConfiguration, button: screenView.botHeroItemsView.necklaceItemButton)
        bindItemButton(for: .earrings, configuration: viewModel.botHeroConfiguration, button: screenView.botHeroItemsView.earringsItemButton)
        bindItemButton(for: .weapons, configuration: viewModel.botHeroConfiguration, button: screenView.botHeroItemsView.weaponPrimaryItemButton)
        bindItemButton(for: .shields, configuration: viewModel.botHeroConfiguration, button: screenView.botHeroItemsView.weaponScondaryItemButton)
        
        bindIsBlockingTwoHands(configuration: viewModel.playerHeroConfiguration, heroItemsView: screenView.userHeroItemsView)
        bindIsBlockingTwoHands(configuration: viewModel.botHeroConfiguration, heroItemsView: screenView.botHeroItemsView)
    }
    
    private func bindLevel(_ publisher: Published<Int16>.Publisher, to levelView: HeroLevelView) {
        publisher
            .receive(on: DispatchQueue.main)
            .sink { level in
                levelView.updateLevelLabel(to: level)
            }
            .store(in: &cancellables)
    }
    
    private func bindAttributes(_ configuration: HeroConfiguration, to attributesView: AttributesView) {
        configuration.$fightStyleAttributes
            .combineLatest(configuration.$levelRandomAttributes, configuration.$itemsAttributes)
            .receive(on: DispatchQueue.main)
            .sink { fightStyleAttributes, levelRandomAttributes, itemsAttributes in
                attributesView.updateAttributes(
                    fightStyleAttributes: fightStyleAttributes,
                    levelRandomAttributes: levelRandomAttributes,
                    itemsAttributes: itemsAttributes
                )
            }
            .store(in: &cancellables)
    }
    
    private func bindFightStyle(_ radioButtonGroup: ElfRadioButtonGroup<SelectFightStyleRadioGroupState>, heroType: HeroType) {
        radioButtonGroup.$selectedValue
            .sink { [weak self] selectedFightStyle in
                guard let self = self else { return }
                self.viewModel.setHeroFightStyle(for: heroType, fightStyle: selectedFightStyle?.toFightStyle())
            }
            .store(in: &cancellables)
    }
    
    private func bindItemButton(for itemType: HeroItemType, configuration: HeroConfiguration, button: ElfButton) {
        configuration.$itemIds
            .map { $0[itemType] ?? nil } // Извлекаем UUID для данного типа предмета
            .receive(on: DispatchQueue.main)
            .sink { [weak button] itemId in
                guard let button = button else { return }
                if let itemId = itemId {
                    button.imageView?.image = UIImage(named: itemId.uuidString.lowercased())
                } else {
                    // Очищаем изображение, если идентификатор отсутствует
                    button.imageView?.image = nil
                }
            }
            .store(in: &cancellables)
    }
    
    private func bindIsBlockingTwoHands(configuration: HeroConfiguration, heroItemsView: HeroItemsView) {
        configuration.$blockingTwoHandsWeaponId
            .sink { [weak heroItemsView] blockingTwoHandsWeaponId in
                guard let heroItemsView = heroItemsView else { return }
                if blockingTwoHandsWeaponId != nil {
                    heroItemsView.weaponSecondaryFilterView.isHidden = false
                } else {
                    heroItemsView.weaponSecondaryFilterView.isHidden = true
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: Actions
    
    private func setupActions() {
        screenView.closeButton.addTarget(viewModel, action: #selector(viewModel.closeButtonAction), for: .touchUpInside)
        
        setupLevelActions(for: screenView.userLevelView, heroType: .player)
        setupLevelActions(for: screenView.botLevelView, heroType: .bot)
        
        setupItemSelection(for: screenView.userHeroItemsView, heroType: .player)
        setupItemSelection(for: screenView.botHeroItemsView, heroType: .bot)
    }
    
    private func setupLevelActions(for levelView: HeroLevelView, heroType: HeroType) {
        levelView.increaseLevelAction = { [weak self] in
            self?.viewModel.changeLevel(heroType, increment: +1)
        }
        levelView.decreaseLevelAction = { [weak self] in
            self?.viewModel.changeLevel(heroType, increment: -1)
        }
    }
    
    private func setupItemSelection(for itemsView: HeroItemsView, heroType: HeroType) {
        itemsView.onItemSelected = { [weak self] heroItemButtonType in
            guard let heroItemType = self?.mapHeroItemButtonTypeToHeroItemType(heroItemButtonType) else { return }
            self?.viewModel.heroItemSelected(for: heroType, heroItemType: heroItemType)
        }
    }
    
    private func mapHeroItemButtonTypeToHeroItemType(_ buttonType: HeroItemButtonType) -> HeroItemType? {
        switch buttonType {
        case .helmet: return .helmet
        case .gloves: return .gloves
        case .shoes: return .shoes
        case .weaponPrimary: return .weapons
        case .weaponSecondary: return .shields
        case .upperBody: return .upperBody
        case .bottomBody: return .bottomBody
        case .shirt: return .shirt
        case .ring: return .ring
        case .necklace: return .necklace
        case .earrings: return .earrings
        }
    }
}

// MARK: - Extensions

extension SelectFightStyleRadioGroupState {
    func toFightStyle() -> FightStyle? {
        switch self {
        case .crit: return .crit
        case .dodge: return .dodge
        case .def: return .def
        }
    }
}
