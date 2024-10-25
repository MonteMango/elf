//
//  BattleSetupViewController.swift
//  
//
//  Created by Vitalii Lytvynov on 28.08.24.
//

import Combine
import elf_Kit
import elf_UIKit

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
    }
    
    private func setupBindings() {
        screenView.closeButton.addTarget(viewModel, action: #selector(viewModel.closeButtonAction), for: .touchUpInside)
        
        screenView.userLevelView.increaseLevelAction = { [weak self] in
            self?.viewModel.changeLevel(.player, increment: +1)
        }
        screenView.userLevelView.decreaseLevelAction = { [weak self] in
            self?.viewModel.changeLevel(.player, increment: -1)
        }
        
        screenView.botLevelView.increaseLevelAction = { [weak self] in
            self?.viewModel.changeLevel(.bot, increment: +1)
        }
        screenView.botLevelView.decreaseLevelAction = { [weak self] in
            self?.viewModel.changeLevel(.bot, increment: -1)
        }
        
        screenView.userHeroItemsView.onItemSelected = { [weak self] heroItemButtonType in
            guard let heroItemType = self?.mapHeroItemButtonTypeToHeroItemType(heroItemButtonType) else { return }
            self?.viewModel.heroItemSelected(for: .player, heroItemType: heroItemType)
        }
        
        screenView.botHeroItemsView.onItemSelected = { [weak self] heroItemButtonType in
            guard let heroItemType = self?.mapHeroItemButtonTypeToHeroItemType(heroItemButtonType) else { return }
            self?.viewModel.heroItemSelected(for: .bot, heroItemType: heroItemType)
        }
        
        viewModel.$playerHeroConfiguration
            .map { $0.level }
            .sink { [weak self] level in
                self?.screenView.userLevelView.updateLevelLabel(to: level)
            }
            .store(in: &cancellables)
        
        viewModel.$botHeroConfiguration
            .map { $0.level }
            .sink { [weak self] level in
                self?.screenView.botLevelView.updateLevelLabel(to: level)
            }
            .store(in: &cancellables)
        
        screenView.userSelectFightStyleStackView.selectFightStyleRadioButtonGroup
            .$selectedValue
            .sink{ [weak self] selectedUserFightStyle in
                guard let self = self else { return }
                switch selectedUserFightStyle {
                case .crit: self.viewModel.setHeroFightStyle(for: .player, fightStyle: .crit)
                case .dodge: self.viewModel.setHeroFightStyle(for: .player, fightStyle: .dodge)
                case .def: self.viewModel.setHeroFightStyle(for: .player, fightStyle: .def)
                case .none: self.viewModel.setHeroFightStyle(for: .player, fightStyle: nil)
                }
            }
            .store(in: &cancellables)
        
        screenView.botSelectFightStyleStackView.selectFightStyleRadioButtonGroup
            .$selectedValue
            .sink{ [weak self] selectedBotFightStyle in
                guard let self = self else { return }
                switch selectedBotFightStyle {
                case .crit: self.viewModel.setHeroFightStyle(for: .bot, fightStyle: .crit)
                case .dodge: self.viewModel.setHeroFightStyle(for: .bot, fightStyle: .dodge)
                case .def: self.viewModel.setHeroFightStyle(for: .bot, fightStyle: .def)
                case .none: self.viewModel.setHeroFightStyle(for: .bot, fightStyle: nil)
                }
            }
            .store(in: &cancellables)
    }
    
    private func mapHeroItemButtonTypeToHeroItemType(_ buttonType: HeroItemButtonType) -> HeroItemType? {
        switch buttonType {
        case .helmet: return .helmet
        case .gloves: return .gloves
        case .shoes: return .shoes
        case .weaponPrimary: return .weaponPrimary
        case .weaponSecondary: return .weaponSecondary
        case .upperBody: return .upperBody
        case .bottomBody: return .bottomBody
        case .shirt: return .shirt
        case .ring: return .ring
        case .necklace: return .necklace
        case .earrings: return .earrings
        }
    }
}
