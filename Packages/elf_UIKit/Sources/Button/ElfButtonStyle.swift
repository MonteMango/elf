//
//  ElfButtonStyle.swift
//
//
//  Created by Vitalii Lytvynov on 17.05.24.
//

import UIKit

public enum ElfButtonStyle {
    case menu
    
    var textStyle: ElfLabelStyle {
        switch self {
        case .menu: return .menuButtonTitle
        }
    }
    
    var borderColor: UIColor {
        switch self {
        case .menu: return UIColor.systemPink
        }
    }
    
    var borderWidth: CGFloat {
        switch self {
        case .menu: return 2
        }
    }
    
    var cornerRadius: CGFloat {
        switch self {
        case .menu: return 0
        }
    }
    
    var height: CGFloat {
        switch self {
        case .menu: return 50
        }
    }
    
    var width: CGFloat {
        switch self {
        case .menu: return 200
        }
    }
    
    // MARK: Normal
    
    var backgroundColor: UIColor {
        switch self {
        case .menu: return UIColor.systemGray
        }
    }
    
    var tintColor: UIColor {
        switch self {
        case .menu: return UIColor.systemBlue
        }
    }
    
    // MARK: Selected
    
    var selectedBackgroundColor: UIColor {
        switch self {
        case .menu: return UIColor.systemGray2
        }
    }
    
    var selectedTintColor: UIColor {
        switch self {
        case .menu: return UIColor.systemOrange
        }
    }
    
    // MARK: Highlighted
    
    var highlightedBackgroundColor: UIColor? {
        switch self {
        case .menu: return UIColor.systemGray3
        }
    }
    
    var highlightedTintColor: UIColor {
        switch self {
        case .menu: return UIColor.systemPurple
        }
    }
}
