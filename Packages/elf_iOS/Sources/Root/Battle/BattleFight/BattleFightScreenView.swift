//
//  BattleFightScreenView.swift
//  
//
//  Created by Vitalii Lytvynov on 28.08.24.
//

import elf_UIKit
import UIKit

internal final class BattleFightScreenView: NiblessView {
    
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
        
    }
    
    private func activateConstraints() {
       
    }
}
