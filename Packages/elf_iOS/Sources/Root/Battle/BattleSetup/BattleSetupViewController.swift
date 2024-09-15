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
        screenView.userSelectFightStyleStackView.selectFightStyleRadioButtonGroup
            .$selectedValue
            .sink{ [weak self] selectedUserFightStyle in
                guard let self = self else { return }
                switch selectedUserFightStyle {
                case .crit: self.viewModel.playerHeroConfiguration.fightStyle = .crit
                case .dodge: self.viewModel.playerHeroConfiguration.fightStyle = .dodge
                case .def: self.viewModel.playerHeroConfiguration.fightStyle = .def
                case .none: self.viewModel.playerHeroConfiguration.fightStyle = nil
                }
            }
            .store(in: &cancellables)
    }
}
