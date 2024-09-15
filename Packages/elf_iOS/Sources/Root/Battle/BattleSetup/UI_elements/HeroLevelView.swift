//
//  HeroLevelView.swift
//
//
//  Created by Vitalii Lytvynov on 15.09.24.
//

import elf_UIKit
import UIKit

internal final class HeroLevelView: NiblessView {
    
    internal var increaseLevelAction: (() -> Void)?
    internal var decreaseLevelAction: (() -> Void)?
    
    // MARK: UI Controls
    
    internal lazy var minusButton: ElfButton = {
        let button = ElfButton(buttonStyle: .selectLevel, centerText: "-")
        return button
    }()
    
    internal lazy var levelLabel: ElfLabel = {
        let label = ElfLabel(labelStyle: .battleLevelLabel, text: "1")
        return label
    }()
    
    internal lazy var plusButton: ElfButton = {
        let button = ElfButton(buttonStyle: .selectLevel, centerText: "+")
        return button
    }()
    
    // MARK: Initializer
    
    internal override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        
        styleView()
        constructHierarchy()
        activateConstraints()
        configureControls()
    }
    
    private func styleView() {
        
    }
    
    private func constructHierarchy() {
        addSubview(minusButton)
        addSubview(levelLabel)
        addSubview(plusButton)
    }
    
    private func activateConstraints() {
        minusButton.translatesAutoresizingMaskIntoConstraints = false
        levelLabel.translatesAutoresizingMaskIntoConstraints = false
        plusButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // plusButton
            minusButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            minusButton.trailingAnchor.constraint(equalTo: levelLabel.centerXAnchor, constant: -20),
            minusButton.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
            minusButton.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
            
            // levelLabel
            levelLabel.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
            levelLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
            
            // minusButton
            plusButton.leadingAnchor.constraint(equalTo: levelLabel.centerXAnchor, constant: 20),
            plusButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            plusButton.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
            plusButton.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor)
        ])
    }
    
    private func configureControls() {
        plusButton.addTarget(self, action: #selector(increaseLevel), for: .touchUpInside)
        minusButton.addTarget(self, action: #selector(decreaseLevel), for: .touchUpInside)
    }
    
    // MARK: Actions
    
    @objc
    private func increaseLevel() {
        increaseLevelAction?()
    }
    
    @objc
    private func decreaseLevel() {
        decreaseLevelAction?()
    }
    
    // MARK: Methods
    
    internal func updateLevelLabel(to level: Int16) {
        levelLabel.text = "\(level)"
    }
}
