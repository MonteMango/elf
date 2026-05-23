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

    // MARK: - Squad Cell State

    public enum SquadCell {
        /// Cell opacity when a squad member is dead.
        public static let dead: Double = 0.45
        /// Cell opacity when a squad member escaped the dungeon.
        public static let escaped: Double = 0.55
    }
}
