//
//  BattleFightScreenView.swift
//  
//
//  Created by Vitalii Lytvynov on 28.08.24.
//

import elf_UIKit
import UIKit

internal final class BattleFightScreenView: NiblessView {
    
    // MARK: UI Controls
    
    internal lazy var closeButton: ElfButton = {
        let button = ElfButton(buttonStyle: .close)
        return button
    }()
    
    internal lazy var userHeroView: HeroView = {
        let view = HeroView()
        return view
    }()
    
    internal lazy var enemyHeroView: HeroView = {
        let view = HeroView()
        return view
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
        addSubview(userHeroView)
        addSubview(enemyHeroView)
    }
    
    private func activateConstraints() {
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        
        userHeroView.translatesAutoresizingMaskIntoConstraints = false
        enemyHeroView.translatesAutoresizingMaskIntoConstraints = false
        
        
        NSLayoutConstraint.activate([
            
            // closeButton
            closeButton.topAnchor.constraint(equalTo: topAnchor),
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 30),
            
            // userHeroView
            userHeroView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            userHeroView.topAnchor.constraint(equalTo: topAnchor, constant: 50),
            
            // enemyHeroView
            enemyHeroView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            enemyHeroView.topAnchor.constraint(equalTo: topAnchor, constant: 50)
        ])
    }
}
