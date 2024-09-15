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
    
    // Battle
    case battleTitleLabel
    
    var font: UIFont {
        switch self {
        case .menuButtonTitle: return UIFont.preferredFont(forTextStyle: .body)
        case .battleTitleLabel: return UIFont.preferredFont(forTextStyle: .title1)
        }
    }
    
    var textAlignment: NSTextAlignment {
        switch self {
        case .menuButtonTitle: return .center
        case .battleTitleLabel: return .left
        }
    }
    
    var textColor: UIColor {
        switch self {
        case .menuButtonTitle: return UIColor.red
        case .battleTitleLabel: return UIColor.red
        }
    }
    
    var numberOfLines: Int {
        switch self {
        case .menuButtonTitle: return 1
        case .battleTitleLabel: return 1
        }
    }
    
    var lineBreakMode: NSLineBreakMode {
        switch self {
        case .menuButtonTitle: return .byTruncatingMiddle
        case .battleTitleLabel: return .byTruncatingMiddle
        }
    }
}
