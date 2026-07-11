//
//  NoOpDebugGameLogger.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// No-op `DebugGameLogger` used as the `testValue` for the `\.debugGameLogger`
/// dependency — lets tests exercise code that logs game state without
/// boilerplate overrides or noisy console output.
public struct NoOpDebugGameLogger: DebugGameLogger {
    public init() {}
    public func logGameSave(game: Game, playTime: TimeInterval) {}
    public func logWorldTurn(_ outcome: WorldTurnOutcome) {}
    public func logError(_ message: String) {}
    public func logDebug(_ message: String) {}
}
