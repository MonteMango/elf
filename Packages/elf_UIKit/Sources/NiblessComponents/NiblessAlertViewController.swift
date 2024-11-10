//
//  NiblessAlertViewController.swift
//  elf_UIKit
//
//  Created by Vitalii Lytvynov on 26.10.24.
//

open class NiblessAlertViewController: NiblessViewController {
    
    public let backgroundScreenView: NiblessAlertView
    
    public init(backgroundScreenView: NiblessAlertView) {
        self.backgroundScreenView = backgroundScreenView
        super.init()
    }
}
