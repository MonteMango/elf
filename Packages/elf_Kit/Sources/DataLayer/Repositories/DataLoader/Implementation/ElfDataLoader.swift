//
//  ElfDataLoader.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 09.07.25.
//

import Foundation
import os.log

public final class ElfDataLoader: DataLoader {

    public init() {}

    public func loadJSON(_ resourceName: String) async throws -> Data {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "json") else {
            throw NSError(
                domain: "ElfDataLoader",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "File \(resourceName).json not found in bundle"]
            )
        }
        return try Data(contentsOf: url)
    }

    public func loadAndDecode<T: Decodable>(
        resourceName: String,
        fallback: @autoclosure () -> T,
        log: OSLog
    ) async -> T {
        let data: Data
        do {
            data = try await loadJSON(resourceName)
        } catch {
            os_log("Could not load %{public}@.json: %{public}@",
                   log: log, type: .error, resourceName, error.localizedDescription)
            return fallback()
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            os_log("Failed to decode %{public}@.json: %{public}@",
                   log: log, type: .error, resourceName, error.localizedDescription)
            return fallback()
        }
    }
}
