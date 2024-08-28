//
//  MenuScreenView.swift
//
//
//  Created by Vitalii Lytvynov on 17.05.24.
//

import elf_UIKit
import UIKit

internal final class MenuScreenView: NiblessView {
    
    // MARK: UI Controls
    
    internal lazy var newGameButton: ElfButton = {
        let button = ElfButton(buttonStyle: .menu, centerText: "New game")
        return button
    }()
    
    internal lazy var battleButton: ElfButton = {
        let button = ElfButton(buttonStyle: .menu, centerText: "Battle")
        return button
    }()
    
    // MARK: Initializer
    
    internal override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        
        styleView()
        constructHierarchy()
        activateConstraints()
    }
    
    private func styleView() {
        backgroundColor = UIColor.systemBackground
    }
    
    private func constructHierarchy() {
        addSubview(newGameButton)
        addSubview(battleButton)
    }
    
    private func activateConstraints() {
        newGameButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            newGameButton.topAnchor.constraint(equalTo: topAnchor, constant: 100),
            newGameButton.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
        
        battleButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            battleButton.topAnchor.constraint(equalTo: newGameButton.bottomAnchor, constant: 30),
            battleButton.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
    }
}
