//
//  BattleContainerViewController.swift
//  
//
//  Created by Vitalii Lytvynov on 28.08.24.
//

import elf_Kit
import elf_UIKit

public final class BattleContainerViewController: NiblessContainerViewController {
    
    // MARK: - Properties
    
    let viewModel: BattleViewModel
    
    // Child View Controller
    let battleSetupViewController: BattleSetupViewController
    
    // MARK: - Methods
    
    internal init(viewModel: BattleViewModel,
                  battleSetupViewController: BattleSetupViewController) {
        self.viewModel = viewModel
        self.battleSetupViewController = battleSetupViewController
        super.init()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    public override func loadView() {
        super.loadView()
        
        addViewController(self.battleSetupViewController)
        showViewController(self.battleSetupViewController)
    }
}
