//
//  ElfOpacity.swift
//  elf_SwiftUI
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// App-wide opacity tokens for UI components.
public enum ElfOpacity {

    // MARK: - GameDay Screen Specific

    public enum GameDay {
        /// Opacity used to render an equipment slot whose visual content
        /// merely mirrors another slot (e.g. the off-hand slot reflecting
        /// a two-handed weapon equipped in the weapons slot).
        public static let mirroredSlot: Double = 0.35
    }
}
