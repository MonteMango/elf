//
//  BattleSetupViewController.swift
//  
//
//  Created by Vitalii Lytvynov on 28.08.24.
//

import elf_Kit
import elf_UIKit

internal final class BattleSetupViewController: NiblessViewController {
   
    // MARK: Properties
    
    private let viewModel: BattleSetupViewModel
    private let screenView: BattleSetupScreenView
    
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
    }
}
