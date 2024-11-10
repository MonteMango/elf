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
    
    // Items
    case itemTitle
    
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
            
        // Items
        case .itemTitle: return UIFont.preferredFont(forTextStyle: .title1)
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
            
        // Items
        case .itemTitle: return .center
        }
    }
    
    var textColor: UIColor {
        switch self {
        case .menuTitleButton: return UIColor.red
        case .actionTitleButton: return UIColor.red
            
        // Battle
        case .battleTitleLabel: return UIColor.red
        case .battleLevelLabel: return UIColor.red
            
        // BattleSetupAttribute
        case .attributePlayerTitleLabel: return UIColor.white
        case .attributePlayerCalculationLabel: return UIColor.white
        case .attributeBotTitleLabel: return UIColor.white
        case .attributeBotCalculationLabel: return UIColor.white
            
        // Items
        case .itemTitle: return UIColor.white
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
            
        // Items
        case .itemTitle: return 3
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
        case .attributeBotCalculationLabel: return .byTruncatingMiddle
            
        // Items
        case .itemTitle: return .byTruncatingMiddle
        }
    }
}
