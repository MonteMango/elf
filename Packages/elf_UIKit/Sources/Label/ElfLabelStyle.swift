//
//  ElfLabelStyle.swift
//  
//
//  Created by Vitalii Lytvynov on 18.05.24.
//

import Foundation
import UIKit

public enum ElfLabelStyle {
    case menuTitleButton
    case actionTitleButton
    
    // Battle
    case battleTitleLabel
    case battleLevelLabel
    
    // BattleSetupAttribute
    case attributePlayerTitleLabel
    case attributePlayerCalculationLabel
    case attributeBotTitleLabel
    case attributeBotCalculationLabel
    
    // BattleSetupArmor
    case armorTitleLabel
    
    // Items
    case itemTitle
    
    // Select Items
    case selectItemsAttributesLabel
    case selectItemsPrevNextButton
    
    var font: UIFont {
        switch self {
        case .menuTitleButton: return UIFont.preferredFont(forTextStyle: .body)
        case .actionTitleButton: return UIFont.preferredFont(forTextStyle: .body)
        
        // Battle
        case .battleTitleLabel: return UIFont.preferredFont(forTextStyle: .subheadline)
        case .battleLevelLabel: return UIFont.preferredFont(forTextStyle: .title1)
            
        // BattleSetupAttribute
        case .attributePlayerTitleLabel: return UIFont.systemFont(ofSize: 13, weight: .bold)
        case .attributePlayerCalculationLabel: return UIFont.systemFont(ofSize: 11, weight: .regular)
        case .attributeBotTitleLabel: return UIFont.systemFont(ofSize: 13, weight: .bold)
        case .attributeBotCalculationLabel: return UIFont.systemFont(ofSize: 11, weight: .regular)
            
        // BattleSetupArmor
        case .armorTitleLabel: return UIFont.systemFont(ofSize: 11, weight: .light)
            
        // Items
        case .itemTitle: return UIFont.preferredFont(forTextStyle: .title1)
            
        // Select Items
        case .selectItemsAttributesLabel: return UIFont.systemFont(ofSize: 13, weight: .regular)
        case .selectItemsPrevNextButton: return UIFont.systemFont(ofSize: 15, weight: .bold)
        }
    }
    
    var textAlignment: NSTextAlignment {
        switch self {
        case .menuTitleButton: return .center
        case .actionTitleButton: return .center
            
        // Battle
        case .battleTitleLabel: return .left
        case .battleLevelLabel: return .center
            
        // BattleSetupAttribute
        case .attributePlayerTitleLabel: return .left
        case .attributePlayerCalculationLabel: return .left
        case .attributeBotTitleLabel: return .right
        case .attributeBotCalculationLabel: return .right
            
        // BattleSetupArmor
        case .armorTitleLabel: return .center
            
        // Items
        case .itemTitle: return .center
            
        // Select Items
        case .selectItemsAttributesLabel: return .center
        case .selectItemsPrevNextButton: return .center
        }
    }
    
    var textColor: UIColor {
        switch self {
        case .menuTitleButton: return UIColor.white
        case .actionTitleButton: return UIColor.white
            
        // Battle
        case .battleTitleLabel: return UIColor.white
        case .battleLevelLabel: return UIColor.white
            
        // BattleSetupAttribute
        case .attributePlayerTitleLabel: return UIColor.white
        case .attributePlayerCalculationLabel: return UIColor.white
        case .attributeBotTitleLabel: return UIColor.white
        case .attributeBotCalculationLabel: return UIColor.white
            
        // BattleSetupArmor
        case .armorTitleLabel: return UIColor.black
            
        // Items
        case .itemTitle: return UIColor.white
            
        // Select Items
        case .selectItemsAttributesLabel: return UIColor.white
        case .selectItemsPrevNextButton: return UIColor.white
        }
    }
    
    var numberOfLines: Int {
        switch self {
        case .menuTitleButton: return 1
        case .actionTitleButton: return 1
            
        // Battle
        case .battleTitleLabel: return 1
        case .battleLevelLabel: return 1
        
        // BattleSetupAttribute
        case .attributePlayerTitleLabel: return 1
        case .attributePlayerCalculationLabel: return 1
        case .attributeBotTitleLabel: return 1
        case .attributeBotCalculationLabel: return 1
            
        // BattleSetupArmor
        case .armorTitleLabel: return 1
            
        // Items
        case .itemTitle: return 3
            
        // Select Items
        case .selectItemsAttributesLabel: return 1
        case .selectItemsPrevNextButton: return 1
        }
    }
    
    var lineBreakMode: NSLineBreakMode {
        switch self {
        case .menuTitleButton: return .byTruncatingMiddle
        case .actionTitleButton: return .byTruncatingMiddle
            
        // Battle
        case .battleTitleLabel: return .byTruncatingMiddle
        case .battleLevelLabel: return .byTruncatingMiddle
        
        // BattleSetupAttribute
        case .attributePlayerTitleLabel: return .byTruncatingMiddle
        case .attributePlayerCalculationLabel: return .byTruncatingMiddle
        case .attributeBotTitleLabel: return .byTruncatingMiddle
        case .attributeBotCalculationLabel: return .byWordWrapping
            
        // BattleSetupArmor
        case .armorTitleLabel: return .byTruncatingMiddle
            
        // Items
        case .itemTitle: return .byTruncatingMiddle
            
        // Select Items
        case .selectItemsAttributesLabel: return .byTruncatingMiddle
        case .selectItemsPrevNextButton: return .byTruncatingMiddle
        }
    }
    
    var adjustsFontSizeToFitWidth: Bool {
        switch self {
        case .menuTitleButton: return false
        case .actionTitleButton: return false
            
        // Battle
        case .battleTitleLabel: return false
        case .battleLevelLabel: return false
        
        // BattleSetupAttribute
        case .attributePlayerTitleLabel: return false
        case .attributePlayerCalculationLabel: return false
        case .attributeBotTitleLabel: return false
        case .attributeBotCalculationLabel: return true
            
        // BattleSetupArmor
        case .armorTitleLabel: return true
            
        // Items
        case .itemTitle: return false
            
        // Select Items
        case .selectItemsAttributesLabel: return false
        case .selectItemsPrevNextButton: return false
        }
    }
}
