//
//  FarmActivityResult.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Unified result type for all farm activities
public enum FarmActivityResult: Sendable, Equatable {
    case fishing(FishingResult)
    case foraging(ForagingResult)
    case mining(MiningResult)
}
