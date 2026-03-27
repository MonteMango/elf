//
//  DropService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 11.12.25.
//

import Foundation

/// Service for converting hunt rewards into displayable drop items
public protocol DropService: Sendable {

    /// Convert HuntRewards into an array of DropItems for UI display
    /// - Parameters:
    ///   - rewards: The rewards calculated by HuntService
    ///   - didWin: Whether the player won the battle (no drops if false)
    /// - Returns: Array of DropItems with enriched display information
    func convertToDropItems(rewards: HuntRewards, didWin: Bool) async -> [DropItem]
}
