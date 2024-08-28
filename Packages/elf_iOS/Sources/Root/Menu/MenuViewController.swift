//
//  MenuViewController.swift
//  
//
//  Created by Vitalii Lytvynov on 17.05.24.
//

import elf_Kit
import elf_UIKit
import UIKit

internal final class MenuViewController: NiblessViewController {
    
    // MARK: Properties
    
    private let viewModel: MenuViewModel
    private let screenView: MenuScreenView
    
    internal init(viewModel: MenuViewModel) {
        self.viewModel = viewModel
        self.screenView = MenuScreenView()
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
        screenView.battleButton.addTarget(
            viewModel,
            action: #selector(viewModel.fightButtonAction),
            for: .touchUpInside)
    }
    
}
