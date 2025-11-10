//
//  SelectFightStyleStackView.swift
//  
//
//  Created by Vitalii Lytvynov on 08.09.24.
//

import elf_UIKit
import UIKit

internal final class SelectFightStyleStackView: NiblessStackView {
    
    // MARK: UI Controls
    
    internal lazy var dodgeButton: ElfButton = {
        let button = ElfButton(buttonStyle: .battleSetupSelectFightStyle)
        button.imageView?.image = UIImage(named: "fightStyle_dodge")
        return button
    }()
    
    internal lazy var critButton: ElfButton = {
        let button = ElfButton(buttonStyle: .battleSetupSelectFightStyle)
        button.imageView?.image = UIImage(named: "fightStyle_crit")
        return button
    }()
    
    internal lazy var defButton: ElfButton = {
        let button = ElfButton(buttonStyle: .battleSetupSelectFightStyle)
        button.imageView?.image = UIImage(named: "fightStyle_def")
        return button
    }()
    
    internal lazy var selectFightStyleRadioButtonGroup: ElfRadioButtonGroup<SelectFightStyleRadioGroupState> = {
        let radioButtonGroup = ElfRadioButtonGroup<SelectFightStyleRadioGroupState>()
        return radioButtonGroup
    }()
    
    // MARK: Initializer
    
    internal override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        
        styleView()
        constructHierarchy()
        activateConstraints()
        configureRadioButtonGroup()
    }
    
    private func styleView() {
        backgroundColor = UIColor.systemBackground
        spacing = 20
        axis = .horizontal
    }
    
    private func constructHierarchy() {
        addArrangedSubview(dodgeButton)
        addArrangedSubview(critButton)
        addArrangedSubview(defButton)
    }
    
    private func activateConstraints() {
        
    }
    
    private func configureRadioButtonGroup() {
        selectFightStyleRadioButtonGroup.addButton(dodgeButton, value: .dodge)
        selectFightStyleRadioButtonGroup.addButton(critButton, value: .crit)
        selectFightStyleRadioButtonGroup.addButton(defButton, value: .def)
    }
}

internal enum SelectFightStyleRadioGroupState {
    case dodge
    case crit
    case def
}
