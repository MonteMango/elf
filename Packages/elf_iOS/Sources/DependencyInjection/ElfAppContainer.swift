//
//  ElfAppContainer.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import elf_Kit
import Foundation

/// Lightweight app-level DI container with sync init.
/// Creates ElfGameContainer asynchronously on the cooperative thread pool.
@Observable
public final class ElfAppContainer {

    /// Game container with all services and repos. Nil until game data is loaded.
    public private(set) var gameContainer: ElfGameContainer?

    public init() {}

    // MARK: - Game Container

    /// Creates game container on the cooperative thread pool.
    /// Called from ElfApp `.task {}` — starts as early as possible.
    @MainActor
    @discardableResult
    public func createGameContainer() async -> ElfGameContainer {
        let container = await ElfGameContainer()
        gameContainer = container
        return container
    }
}
