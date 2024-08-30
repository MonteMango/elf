//
//  BattleSetupScreenView.swift
//  
//
//  Created by Vitalii Lytvynov on 28.08.24.
//

import elf_UIKit
import UIKit

internal final class BattleSetupScreenView: NiblessView {
    
    // MARK: UI Controls
    
    internal lazy var closeButton: ElfButton = {
        let button = ElfButton(buttonStyle: .close)
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
        addSubview(closeButton)
    }
    
    private func activateConstraints() {
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: topAnchor),
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
}
