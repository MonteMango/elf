//
//  ElfRadioButtonGroup.swift
//
//
//  Created by Vitalii Lytvynov on 08.09.24.
//

import Combine
import Foundation

public final class ElfRadioButtonGroup<T: Equatable>: ObservableObject {
    private var buttons: [ElfButton] = []
    private var buttonValues: [ElfButton: T] = [:]
    
    @Published private(set) public var selectedValue: T?
    
    public init() { }
    
    public func addButton(_ button: ElfButton, value: T) {
        buttons.append(button)
        buttonValues[button] = value
        button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
    }
    
    @objc 
    private func buttonTapped(_ sender: ElfButton) {
        selectButton(sender)
    }
    
    private func selectButton(_ button: ElfButton) {
        buttons.forEach { $0.isSelected = false }
        button.isSelected = true
        selectedValue = buttonValues[button]
    }
}
