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
    case item
    case jewelryItem
    
    // SelectItem
    case selectItemEquip
    case selectItemPrevNextAttribute
    
    var borderColor: UIColor? {
        switch self {
        case .menu: return UIColor.systemPink
        case .close: return nil
        case .actionButton: return UIColor.systemPink
            
        // Battle
        case .selectFightStyle: return UIColor.systemGray
        case .selectLevel: return UIColor.systemGray
        case .item: return UIColor.systemGray
        case .jewelryItem: return UIColor.systemGray
            
        // SelectItem
        case .selectItemEquip: return UIColor.systemGray
        case .selectItemPrevNextAttribute: return nil
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
        case .item: return 2.0
        case .jewelryItem: return 2.0
            
        // SelectItem
        case .selectItemEquip: return 2.0
        case .selectItemPrevNextAttribute: return 0.0
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
        case .item: return nil
        case .jewelryItem: return nil
            
        // SelectItem
        case .selectItemEquip: return nil
        case .selectItemPrevNextAttribute: return nil
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
        case .item: return 45.0
        case .jewelryItem: return 35.0
            
        // SelectItem
        case .selectItemEquip: return 50.0
        case .selectItemPrevNextAttribute: return 50.0
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
        case .item: return 45.0
        case .jewelryItem: return 35.0
        
        // SelectItem
        case .selectItemEquip: return 180.0
        case .selectItemPrevNextAttribute: return 50.0
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
        case .item: return UIColor.systemBlue
        case .jewelryItem: return UIColor.systemBlue
            
        // SelectItem
        case .selectItemEquip: return UIColor.systemBlue
        case .selectItemPrevNextAttribute: return UIColor.systemBlue
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
        case .item: return UIColor.systemBlue
        case .jewelryItem: return UIColor.systemBlue
            
        // SelectItem
        case .selectItemEquip: return UIColor.systemBlue
        case .selectItemPrevNextAttribute: return UIColor.systemBlue
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
        case .item: return UIColor.systemGray2
        case .jewelryItem: return UIColor.systemGray2
            
        // SelectItem
        case .selectItemEquip: return UIColor.systemGray2
        case .selectItemPrevNextAttribute: return UIColor.systemGray2
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
        case .item: return UIColor.systemOrange
        case .jewelryItem: return UIColor.systemOrange
            
        // SelectItem
        case.selectItemEquip: return UIColor.systemOrange
        case .selectItemPrevNextAttribute: return UIColor.systemOrange
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
        case .item: return UIColor.systemRed
        case .jewelryItem: return UIColor.systemRed
        
        // SelectItem
        case .selectItemEquip: return UIColor.systemRed
        case .selectItemPrevNextAttribute: return nil
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
        case .item: return 0.0
        case .jewelryItem: return 0.0
            
        // SelectItem
        case .selectItemEquip: return 0.0
        case .selectItemPrevNextAttribute: return 0.0
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
        case .item: return UIColor.systemGray3
        case .jewelryItem: return UIColor.systemGray3
            
        // SelectItem
        case .selectItemEquip: return UIColor.systemGray3
        case .selectItemPrevNextAttribute: return nil
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
        case .item: return UIColor.systemPurple
        case .jewelryItem: return UIColor.systemPurple
            
        // SelectItem
        case .selectItemEquip: return UIColor.systemPurple
        case .selectItemPrevNextAttribute: return UIColor.systemPurple
        }
    }
}
