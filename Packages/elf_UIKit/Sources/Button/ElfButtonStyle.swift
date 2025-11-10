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
    
    // BattleSetup
    case battleSetupSelectFightStyle
    case battleSetupSelectLevel
    case battleSetupItem
    case battleSetupJewelryItem
    
    // SelectItem
    case selectItemEquip
    case selectItemPrevNextAttribute
    
    // Battle
    case battleIttem
    case battleJewelryItem
    
    var borderColor: UIColor? {
        switch self {
        case .menu: return UIColor.systemPink
        case .close: return nil
        case .actionButton: return UIColor.systemPink
            
        // BattleSetup
        case .battleSetupSelectFightStyle: return UIColor.systemGray
        case .battleSetupSelectLevel: return UIColor.systemGray
        case .battleSetupItem: return UIColor.systemGray
        case .battleSetupJewelryItem: return UIColor.systemGray
            
        // SelectItem
        case .selectItemEquip: return UIColor.systemGray
        case .selectItemPrevNextAttribute: return nil
            
        // Battle
        case .battleIttem: return nil
        case .battleJewelryItem: return nil
        }
    }
    
    var borderWidth: CGFloat {
        switch self {
        case .menu: return 2.0
        case .close: return 0.0
        case .actionButton: return 2.0
        
        // BattleSetup
        case .battleSetupSelectFightStyle: return 2.0
        case .battleSetupSelectLevel: return 2.0
        case .battleSetupItem: return 2.0
        case .battleSetupJewelryItem: return 2.0
            
        // SelectItem
        case .selectItemEquip: return 2.0
        case .selectItemPrevNextAttribute: return 0.0
            
        // Battle
        case .battleIttem: return 0.0
        case .battleJewelryItem: return 0.0
        }
    }
    
    var cornerRadius: CGFloat? {
        switch self {
        case .menu: return nil
        case .close: return nil
        case .actionButton: return nil
            
        // BattleSetup
        case .battleSetupSelectFightStyle: return nil
        case .battleSetupSelectLevel: return 17.5
        case .battleSetupItem: return nil
        case .battleSetupJewelryItem: return nil
            
        // SelectItem
        case .selectItemEquip: return nil
        case .selectItemPrevNextAttribute: return nil
        
        // Battle
        case .battleIttem: return nil
        case .battleJewelryItem: return nil
        }
    }
    
    var height: CGFloat {
        switch self {
        case .menu: return 50.0
        case .close: return 50.0
        case .actionButton: return 50.0
            
        // BattleSetup
        case .battleSetupSelectFightStyle: return 45.0
        case .battleSetupSelectLevel: return 35.0
        case .battleSetupItem: return 45.0
        case .battleSetupJewelryItem: return 35.0
            
        // SelectItem
        case .selectItemEquip: return 50.0
        case .selectItemPrevNextAttribute: return 50.0
            
        // Battle
        case .battleIttem: return 35.0
        case .battleJewelryItem: return 25.0
        }
    }
    
    var width: CGFloat {
        switch self {
        case .menu: return 200.0
        case .close: return 50.0
        case .actionButton: return 200.0
            
        // BattleSetup
        case .battleSetupSelectFightStyle: return 45.0
        case .battleSetupSelectLevel: return 35.0
        case .battleSetupItem: return 45.0
        case .battleSetupJewelryItem: return 35.0
        
        // SelectItem
        case .selectItemEquip: return 180.0
        case .selectItemPrevNextAttribute: return 50.0
        
        // Battle
        case .battleIttem: return 35.0
        case .battleJewelryItem: return 25.0
        }
    }
    
    // MARK: Normal
    
    var backgroundColor: UIColor {
        switch self {
        case .menu: return UIColor.systemGray
        case .close: return UIColor.systemRed
        case .actionButton: return UIColor.systemGray
        
        // BattleSetup
        case.battleSetupSelectFightStyle: return UIColor.systemBlue
        case .battleSetupSelectLevel: return UIColor.systemBlue
        case .battleSetupItem: return UIColor.systemBlue
        case .battleSetupJewelryItem: return UIColor.systemBlue
            
        // SelectItem
        case .selectItemEquip: return UIColor.systemBlue
        case .selectItemPrevNextAttribute: return UIColor.systemBlue
            
        // Battle
        case .battleIttem: return UIColor.clear
        case .battleJewelryItem: return UIColor.clear
        }
    }
    
    var tintColor: UIColor {
        switch self {
        case .menu: return UIColor.systemBlue
        case .close: return UIColor.systemBlue
        case .actionButton: return UIColor.systemBlue
            
        // BattleSetup
        case .battleSetupSelectFightStyle: return UIColor.systemBlue
        case .battleSetupSelectLevel: return UIColor.systemBlue
        case .battleSetupItem: return UIColor.systemBlue
        case .battleSetupJewelryItem: return UIColor.systemBlue
            
        // SelectItem
        case .selectItemEquip: return UIColor.systemBlue
        case .selectItemPrevNextAttribute: return UIColor.systemBlue
            
        // Battle
        case .battleIttem: return UIColor.systemBlue
        case .battleJewelryItem: return UIColor.systemBlue
        }
    }
    
    // MARK: Selected
    
    var selectedBackgroundColor: UIColor {
        switch self {
        case .menu: return UIColor.systemGray2
        case .close: return UIColor.systemGray2
        case .actionButton: return UIColor.systemGray2
            
        // BattleSetup
        case .battleSetupSelectFightStyle: return UIColor.systemGray2
        case .battleSetupSelectLevel: return UIColor.systemGray2
        case .battleSetupItem: return UIColor.systemGray2
        case .battleSetupJewelryItem: return UIColor.systemGray2
            
        // SelectItem
        case .selectItemEquip: return UIColor.systemGray2
        case .selectItemPrevNextAttribute: return UIColor.systemGray2
            
        // Battle
        case .battleIttem: return UIColor.systemGray2
        case .battleJewelryItem: return UIColor.systemGray2
        }
    }
    
    var selectedTintColor: UIColor {
        switch self {
        case .menu: return UIColor.systemOrange
        case .close: return UIColor.systemOrange
        case .actionButton: return UIColor.systemOrange
            
        // BattleSetup
        case .battleSetupSelectFightStyle: return UIColor.systemOrange
        case .battleSetupSelectLevel: return UIColor.systemOrange
        case .battleSetupItem: return UIColor.systemOrange
        case .battleSetupJewelryItem: return UIColor.systemOrange
            
        // SelectItem
        case.selectItemEquip: return UIColor.systemOrange
        case .selectItemPrevNextAttribute: return UIColor.systemOrange
            
        // Battle
        case .battleIttem: return UIColor.systemOrange
        case .battleJewelryItem: return UIColor.systemOrange
        }
    }
    
    var selectedBorderColor: UIColor? {
        switch self {
        case .menu: return nil
        case .close: return nil
        case .actionButton: return nil
            
        // BattleSetup
        case .battleSetupSelectFightStyle: return UIColor.systemRed
        case .battleSetupSelectLevel: return UIColor.systemRed
        case .battleSetupItem: return UIColor.systemRed
        case .battleSetupJewelryItem: return UIColor.systemRed
        
        // SelectItem
        case .selectItemEquip: return UIColor.systemRed
        case .selectItemPrevNextAttribute: return nil
            
        // Battle
        case .battleIttem: return UIColor.systemRed
        case .battleJewelryItem: return UIColor.systemRed
        }
    }
    
    var selectedBorderWidth: CGFloat {
        switch self {
        case .menu: return 0.0
        case .close: return 0.0
        case .actionButton: return 0.0
            
        // BattleSetup
        case .battleSetupSelectFightStyle: return 6.0
        case .battleSetupSelectLevel: return 0.0
        case .battleSetupItem: return 0.0
        case .battleSetupJewelryItem: return 0.0
            
        // SelectItem
        case .selectItemEquip: return 0.0
        case .selectItemPrevNextAttribute: return 0.0
            
        // Battle
        case .battleIttem: return 0.0
        case .battleJewelryItem: return 0.0
        }
    }
    
    // MARK: Highlighted
    
    var highlightedBackgroundColor: UIColor? {
        switch self {
        case .menu: return UIColor.systemGray3
        case .close: return UIColor.systemGray3
        case .actionButton: return UIColor.systemGray3
            
        // BattleSetup
        case .battleSetupSelectFightStyle: return UIColor.systemGray3
        case .battleSetupSelectLevel: return UIColor.systemGray3
        case .battleSetupItem: return UIColor.systemGray3
        case .battleSetupJewelryItem: return UIColor.systemGray3
            
        // SelectItem
        case .selectItemEquip: return UIColor.systemGray3
        case .selectItemPrevNextAttribute: return nil
        
        // Battle
        case .battleIttem: return UIColor.systemGray3
        case .battleJewelryItem: return UIColor.systemGray3
        }
    }
    
    var highlightedTintColor: UIColor {
        switch self {
        case .menu: return UIColor.systemPurple
        case .close: return UIColor.systemPurple
        case .actionButton: return UIColor.systemPurple
            
        // BattleSetup
        case .battleSetupSelectFightStyle: return UIColor.systemPurple
        case .battleSetupSelectLevel: return UIColor.systemPurple
        case .battleSetupItem: return UIColor.systemPurple
        case .battleSetupJewelryItem: return UIColor.systemPurple
            
        // SelectItem
        case .selectItemEquip: return UIColor.systemPurple
        case .selectItemPrevNextAttribute: return UIColor.systemPurple
            
        // Battle
        case .battleIttem: return UIColor.systemPurple
        case .battleJewelryItem: return UIColor.systemPurple
        }
    }
}
