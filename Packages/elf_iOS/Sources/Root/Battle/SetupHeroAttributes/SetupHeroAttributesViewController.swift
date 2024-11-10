//
//  SetupHeroAttributesViewController.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 26.10.24.
//

import elf_Kit
import elf_UIKit
import UIKit

internal final class SetupHeroAttributesViewController: NiblessAlertViewController {
    
    private let viewModel: SetupHeroAttributesViewModel
    private let screenView: SetupHeroAttributesScreenView
    
    internal init(viewModel: SetupHeroAttributesViewModel) {
        self.viewModel = viewModel
        self.screenView = SetupHeroAttributesScreenView()
        super.init(backgroundScreenView: screenView)
    }
}
