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
    
    internal lazy var userSelectFightStyleLabel: ElfLabel = {
        let label = ElfLabel(labelStyle: .battleTitleLabel, text: "Fight style")
        return label
    }()
    
    internal lazy var userSelectFightStyleStackView: SelectFightStyleStackView = {
        let stackView = SelectFightStyleStackView()
        return stackView
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
        addSubview(userSelectFightStyleLabel)
        addSubview(userSelectFightStyleStackView)
    }
    
    private func activateConstraints() {
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        userSelectFightStyleLabel.translatesAutoresizingMaskIntoConstraints = false
        userSelectFightStyleStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // closeButton
            closeButton.topAnchor.constraint(equalTo: topAnchor),
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            // userSelectFightStyleLabel
            userSelectFightStyleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            userSelectFightStyleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 70),
            
            // userSelectFightStyleStackView
            userSelectFightStyleStackView.topAnchor.constraint(equalTo: userSelectFightStyleLabel.bottomAnchor, constant: 5),
            userSelectFightStyleStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 70)
        ])
    }
}
