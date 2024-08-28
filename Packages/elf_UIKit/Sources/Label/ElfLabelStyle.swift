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
    
    var font: UIFont {
        switch self {
        case .menuButtonTitle: return UIFont.preferredFont(forTextStyle: .body)
        }
    }
    
    var textAlignment: NSTextAlignment {
        switch self {
        case .menuButtonTitle: return .center
        }
    }
    
    var textColor: UIColor {
        switch self {
        case .menuButtonTitle: return UIColor.red
        }
    }
    
    var numberOfLines: Int {
        switch self {
        case .menuButtonTitle: return 1
        }
    }
    
    var lineBreakMode: NSLineBreakMode {
        switch self {
        case .menuButtonTitle: return .byTruncatingMiddle
        }
    }
}
