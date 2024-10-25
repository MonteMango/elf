//
//  ElfLabelStyle.swift
//  
//
//  Created by Vitalii Lytvynov on 18.05.24.
//

import Foundation
import UIKit

public enum ElfLabelStyle {
    case menuButtonTitle
    case actionButtonTitle
    
    // Battle
    case battleTitleLabel
    case battleLevelLabel
    
    // Items
    case itemTitle
    
    var font: UIFont {
        switch self {
        case .menuButtonTitle: return UIFont.preferredFont(forTextStyle: .body)
        case .actionButtonTitle: return UIFont.preferredFont(forTextStyle: .body)
        
        // Battle
        case .battleTitleLabel: return UIFont.preferredFont(forTextStyle: .subheadline)
        case .battleLevelLabel: return UIFont.preferredFont(forTextStyle: .title1)
            
        // Items
        case .itemTitle: return UIFont.preferredFont(forTextStyle: .title1)
        }
    }
    
    var textAlignment: NSTextAlignment {
        switch self {
        case .menuButtonTitle: return .center
        case .actionButtonTitle: return .center
            
        // Battle
        case .battleTitleLabel: return .left
        case .battleLevelLabel: return .center
            
        // Items
        case .itemTitle: return .center
        }
    }
    
    var textColor: UIColor {
        switch self {
        case .menuButtonTitle: return UIColor.red
        case .actionButtonTitle: return UIColor.red
            
        // Battle
        case .battleTitleLabel: return UIColor.red
        case .battleLevelLabel: return UIColor.red
            
        // Items
        case .itemTitle: return UIColor.white
        }
    }
    
    var numberOfLines: Int {
        switch self {
        case .menuButtonTitle: return 1
        case .actionButtonTitle: return 1
            
        // Battle
        case .battleTitleLabel: return 1
        case .battleLevelLabel: return 1
            
        // Items
        case .itemTitle: return 3
        }
    }
    
    var lineBreakMode: NSLineBreakMode {
        switch self {
        case .menuButtonTitle: return .byTruncatingMiddle
        case .actionButtonTitle: return .byTruncatingMiddle
            
        // Battle
        case .battleTitleLabel: return .byTruncatingMiddle
        case .battleLevelLabel: return .byTruncatingMiddle
            
        // Items
        case .itemTitle: return .byTruncatingMiddle
        }
    }
}
