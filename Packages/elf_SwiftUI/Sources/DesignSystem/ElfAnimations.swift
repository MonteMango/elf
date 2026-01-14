//
//  ElfAnimations.swift
//  elf_SwiftUI
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// App-wide animation timing constants.
public enum ElfAnimations {

    // MARK: - Durations

    public enum Duration {
        public static let instant: Double = 0.1
        public static let fast: Double = 0.2
        public static let normal: Double = 0.35
        public static let slow: Double = 0.5
        public static let xpBarFill: Double = 1.0
    }

    // MARK: - Delays

    public enum Delay {
        public static let short: Double = 0.15
        public static let medium: Double = 0.3
        public static let long: Double = 0.6
        public static let stagger: Double = 0.2
    }

    // MARK: - Battle Result

    public enum BattleResult {
        public static let backgroundFade: Double = 0.25
        public static let backgroundFadeDuration: Double = 0.25  // Alias for backgroundFade
        public static let cardAppearDelay: Double = 0.15
        public static let cardAppearDuration: Double = 0.35
        public static let headerAppearDelay: Double = 0.3
        public static let xpBarFillDelay: Double = 0.6
        public static let xpBarFillDuration: Double = 1.0
        public static let levelUpDelay: Double = 1.6
        public static let dropItemDelay: Double = 1.8
        public static let dropItemStagger: Double = 0.2
        public static let continueButtonDelay: Double = 0.4
    }
}
