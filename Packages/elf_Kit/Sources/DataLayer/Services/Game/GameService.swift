//
//  GameService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 02.12.25.
//

import Foundation

/// Combined protocol for full game service functionality
/// - GameStateService: State mutations (requires @MainActor)
/// - GamePersistenceService: Save/load operations (can run on background)
public typealias GameService = GameStateService & GamePersistenceService
