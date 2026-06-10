//
//  WeaponSubcategory.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

public enum WeaponSubcategory: String, CaseIterable, Sendable {
    case all
    case oneHand
    case twoHands
    case shields

    public var displayTitle: String {
        switch self {
        case .all:
            return "all"
        case .oneHand:
            return "one hand"
        case .twoHands:
            return "two\nhands"
        case .shields:
            return "shields"
        }
    }
}
