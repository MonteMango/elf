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
    
    // Battle
    case selectFightStyle
    
    var textStyle: ElfLabelStyle? {
        switch self {
        case .menu: return .menuButtonTitle
        case .close: return nil
        case .selectFightStyle: return nil
        }
    }
    
    var borderColor: UIColor? {
        switch self {
        case .menu: return UIColor.systemPink
        case .close: return nil
        case .selectFightStyle: return UIColor.systemGray
        }
    }
    
    var borderWidth: CGFloat {
        switch self {
        case .menu: return 2.0
        case .close: return 0.0
        case .selectFightStyle: return 2.0
        }
    }
    
    var cornerRadius: CGFloat? {
        switch self {
        case .menu: return nil
        case .close: return nil
        case .selectFightStyle: return nil
        }
    }
    
    var height: CGFloat {
        switch self {
        case .menu: return 50
        case .close: return 50
        case .selectFightStyle: return 45
        }
    }
    
    var width: CGFloat {
        switch self {
        case .menu: return 200
        case .close: return 50
        case .selectFightStyle: return 45
        }
    }
    
    // MARK: Normal
    
    var backgroundColor: UIColor {
        switch self {
        case .menu: return UIColor.systemGray
        case .close: return UIColor.systemRed
        case.selectFightStyle: return UIColor.systemBlue
        }
    }
    
    var tintColor: UIColor {
        switch self {
        case .menu: return UIColor.systemBlue
        case .close: return UIColor.systemBlue
        case .selectFightStyle: return UIColor.systemBlue
        }
    }
    
    // MARK: Selected
    
    var selectedBackgroundColor: UIColor {
        switch self {
        case .menu: return UIColor.systemGray2
        case .close: return UIColor.systemGray2
        case .selectFightStyle: return UIColor.systemGray2
        }
    }
    
    var selectedTintColor: UIColor {
        switch self {
        case .menu: return UIColor.systemOrange
        case .close: return UIColor.systemOrange
        case .selectFightStyle: return UIColor.systemOrange
        }
    }
    
    var selectedBorderColor: UIColor? {
        switch self {
        case .menu: return nil
        case .close: return nil
        case .selectFightStyle: return UIColor.systemRed
        }
    }
    
    var selectedBorderWidth: CGFloat {
        switch self {
        case .menu: return 0.0
        case .close: return 0.0
        case .selectFightStyle: return 6.0
        }
    }
    
    // MARK: Highlighted
    
    var highlightedBackgroundColor: UIColor? {
        switch self {
        case .menu: return UIColor.systemGray3
        case .close: return UIColor.systemGray3
        case .selectFightStyle: return UIColor.systemGray3
        }
    }
    
    var highlightedTintColor: UIColor {
        switch self {
        case .menu: return UIColor.systemPurple
        case .close: return UIColor.systemPurple
        case .selectFightStyle: return UIColor.systemPurple
        }
    }
}
