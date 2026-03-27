//
//  DataLoader.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 09.07.25.
//

import Foundation
import os.log

public protocol DataLoader: Sendable {
    func loadJSON(_ resourceName: String) async throws -> Data

    /// Loads JSON file and decodes it into specified type, returning fallback on failure
    ///
    /// - Parameters:
    ///   - resourceName: JSON file name without extension
    ///   - fallback: Value to return if loading or decoding fails
    ///   - log: OSLog instance for error logging
    /// - Returns: Decoded value or fallback
    func loadAndDecode<T: Decodable>(
        resourceName: String,
        fallback: @autoclosure () -> T,
        log: OSLog
    ) async -> T
}
