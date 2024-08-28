//
//  RootContainerViewController.swift
//
//
//  Created by Vitalii Lytvynov on 01.05.24.
//

import elf_Kit
import elf_UIKit

public final class RootContainerViewController: NiblessContainerViewController {
    
    // MARK: - Properties
    
    let viewModel: RootViewModel
    
    // Child View Controller
    let menuViewController: MenuViewController
    
    // MARK: - Methods
    
    internal init(viewModel: RootViewModel,
                menuViewController: MenuViewController) {
        self.viewModel = viewModel
        self.menuViewController = menuViewController
        super.init()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    public override func loadView() {
        super.loadView()
        
        addViewController(self.menuViewController)
        showViewController(self.menuViewController)
    }
}
