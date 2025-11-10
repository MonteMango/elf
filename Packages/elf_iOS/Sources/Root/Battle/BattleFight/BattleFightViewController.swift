//
//  BattleFightViewController.swift
//  
//
//  Created by Vitalii Lytvynov on 28.08.24.
//

import elf_Kit
import elf_UIKit

internal final class BattleFightViewController: NiblessViewController {
   
    // MARK: Properties
    
    private let viewModel: BattleFightViewModel
    private let screenView: BattleFightScreenView
    
    internal init(viewModel: BattleFightViewModel) {
        self.viewModel = viewModel
        self.screenView = BattleFightScreenView()
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
    
    private func setupBindings() {
        
    }
    
    private func setupActions() {
        screenView.closeButton.addTarget(viewModel, action: #selector(viewModel.closeButtonAction), for: .touchUpInside)
    }
}
