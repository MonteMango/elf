//
//  GameSaveError.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 04.12.25.
//

import Foundation

/// Errors that can occur during game save/load operations
enum GameSaveError: Error, LocalizedError {
    // TODO: [persistence/P1] Currently unused — wire up in FileGameSaveStorage.save/load.
    // See matching TODO there for the SHA256 integrity-check plan.
    case checksumMismatch
    case unsupportedVersion(Int)
    case migrationFailed(from: Int, to: Int)
    case corruptedData
    case slotNotFound(String)
    case fileWriteFailed(Error)
    case fileReadFailed(Error)
    case encodingFailed(Error)
    case decodingFailed(Error)
    case missingItemData(itemId: UUID, itemType: String)

    public var errorDescription: String? {
        switch self {
        case .checksumMismatch:
            return "Save file integrity check failed. The save may have been corrupted or modified."
        case .unsupportedVersion(let version):
            return "Save file version \(version) is not supported."
        case .migrationFailed(let from, let to):
            return "Failed to migrate save from version \(from) to \(to)."
        case .corruptedData:
            return "Save file data is corrupted and cannot be loaded."
        case .slotNotFound(let slotId):
            return "Save slot '\(slotId)' was not found."
        case .fileWriteFailed(let error):
            return "Failed to write save file: \(error.localizedDescription)"
        case .fileReadFailed(let error):
            return "Failed to read save file: \(error.localizedDescription)"
        case .encodingFailed(let error):
            return "Failed to encode game data: \(error.localizedDescription)"
        case .decodingFailed(let error):
            return "Failed to decode save file: \(error.localizedDescription)"
        case .missingItemData(let itemId, let itemType):
            return "Item '\(itemType)' with ID \(itemId) not found in game data. The item may have been removed in an update."
        }
    }
}
