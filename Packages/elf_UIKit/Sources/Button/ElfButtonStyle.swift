//
//  ElfButtonStyle.swift
//
//
//  Created by Vitalii Lytvynov on 17.05.24.
//

import UIKit

public enum ElfButtonStyle {
    case menu
    case close
    case actionButton
    
    // Battle
    case selectFightStyle
    case selectLevel
    
    var borderColor: UIColor? {
        switch self {
        case .menu: return UIColor.systemPink
        case .close: return nil
        case .actionButton: return UIColor.systemPink
            
        // Battle
        case .selectFightStyle: return UIColor.systemGray
        case .selectLevel: return UIColor.systemGray
        }
    }
    
    var borderWidth: CGFloat {
        switch self {
        case .menu: return 2.0
        case .close: return 0.0
        case .actionButton: return 2.0
        
        // Battle
        case .selectFightStyle: return 2.0
        case .selectLevel: return 2.0
        }
    }
    
    var cornerRadius: CGFloat? {
        switch self {
        case .menu: return nil
        case .close: return nil
        case .actionButton: return nil
            
        // Battle
        case .selectFightStyle: return nil
        case .selectLevel: return 17.5
        }
    }
    
    var height: CGFloat {
        switch self {
        case .menu: return 50.0
        case .close: return 50.0
        case .actionButton: return 50.0
            
        // Battle
        case .selectFightStyle: return 45.0
        case .selectLevel: return 35.0
        }
    }
    
    var width: CGFloat {
        switch self {
        case .menu: return 200.0
        case .close: return 50.0
        case .actionButton: return 200.0
            
        // Battle
        case .selectFightStyle: return 45.0
        case .selectLevel: return 35.0
        }
    }
    
    // MARK: Normal
    
    var backgroundColor: UIColor {
        switch self {
        case .menu: return UIColor.systemGray
        case .close: return UIColor.systemRed
        case .actionButton: return UIColor.systemGray
        
        // Battle
        case.selectFightStyle: return UIColor.systemBlue
        case .selectLevel: return UIColor.systemBlue
        }
    }
    
    var tintColor: UIColor {
        switch self {
        case .menu: return UIColor.systemBlue
        case .close: return UIColor.systemBlue
        case .actionButton: return UIColor.systemBlue
            
        // Battle
        case .selectFightStyle: return UIColor.systemBlue
        case .selectLevel: return UIColor.systemBlue
        }
    }
    
    // MARK: Selected
    
    var selectedBackgroundColor: UIColor {
        switch self {
        case .menu: return UIColor.systemGray2
        case .close: return UIColor.systemGray2
        case .actionButton: return UIColor.systemGray2
            
        // Battle
        case .selectFightStyle: return UIColor.systemGray2
        case .selectLevel: return UIColor.systemGray2
        }
    }
    
    var selectedTintColor: UIColor {
        switch self {
        case .menu: return UIColor.systemOrange
        case .close: return UIColor.systemOrange
        case .actionButton: return UIColor.systemOrange
            
        // Battle
        case .selectFightStyle: return UIColor.systemOrange
        case .selectLevel: return UIColor.systemOrange
        }
    }
    
    var selectedBorderColor: UIColor? {
        switch self {
        case .menu: return nil
        case .close: return nil
        case .actionButton: return nil
            
        // Battle
        case .selectFightStyle: return UIColor.systemRed
        case .selectLevel: return UIColor.systemRed
        }
    }
    
    var selectedBorderWidth: CGFloat {
        switch self {
        case .menu: return 0.0
        case .close: return 0.0
        case .actionButton: return 0.0
            
        // Battle
        case .selectFightStyle: return 6.0
        case .selectLevel: return 0.0
        }
    }
    
    // MARK: Highlighted
    
    var highlightedBackgroundColor: UIColor? {
        switch self {
        case .menu: return UIColor.systemGray3
        case .close: return UIColor.systemGray3
        case .actionButton: return UIColor.systemGray3
            
        // Battle
        case .selectFightStyle: return UIColor.systemGray3
        case .selectLevel: return UIColor.systemGray3
        }
    }
    
    var highlightedTintColor: UIColor {
        switch self {
        case .menu: return UIColor.systemPurple
        case .close: return UIColor.systemPurple
        case .actionButton: return UIColor.systemPurple
            
        // Battle
        case .selectFightStyle: return UIColor.systemPurple
        case .selectLevel: return UIColor.systemPurple
        }
    }
}
