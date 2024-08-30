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
    
    var textStyle: ElfLabelStyle? {
        switch self {
        case .menu: return .menuButtonTitle
        case .close: return nil
        }
    }
    
    var borderColor: UIColor? {
        switch self {
        case .menu: return UIColor.systemPink
        case .close: return nil
        }
    }
    
    var borderWidth: CGFloat? {
        switch self {
        case .menu: return 2
        case .close: return nil
        }
    }
    
    var cornerRadius: CGFloat? {
        switch self {
        case .menu: return nil
        case .close: return nil
        }
    }
    
    var height: CGFloat {
        switch self {
        case .menu: return 50
        case .close: return 50
        }
    }
    
    var width: CGFloat {
        switch self {
        case .menu: return 200
        case .close: return 50
        }
    }
    
    // MARK: Normal
    
    var backgroundColor: UIColor {
        switch self {
        case .menu: return UIColor.systemGray
        case .close: return UIColor.systemRed
        }
    }
    
    var tintColor: UIColor {
        switch self {
        case .menu: return UIColor.systemBlue
        case .close: return UIColor.systemBlue
        }
    }
    
    // MARK: Selected
    
    var selectedBackgroundColor: UIColor {
        switch self {
        case .menu: return UIColor.systemGray2
        case .close: return UIColor.systemGray2
        }
    }
    
    var selectedTintColor: UIColor {
        switch self {
        case .menu: return UIColor.systemOrange
        case .close: return UIColor.systemOrange
        }
    }
    
    // MARK: Highlighted
    
    var highlightedBackgroundColor: UIColor? {
        switch self {
        case .menu: return UIColor.systemGray3
        case .close: return UIColor.systemGray3
        }
    }
    
    var highlightedTintColor: UIColor {
        switch self {
        case .menu: return UIColor.systemPurple
        case .close: return UIColor.systemPurple
        }
    }
}
