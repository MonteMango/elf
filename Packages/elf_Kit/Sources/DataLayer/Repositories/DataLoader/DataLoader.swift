//
//  DataLoader.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 09.07.25.
//

import Foundation
import os.log

public protocol DataLoader: Sendable {
    func loadJSON(_ resourceName: String) throws -> Data
}

extension DataLoader {

    func loadAndDecode<T: Decodable>(
        resourceName: String,
        fallback: @autoclosure () -> T,
        log: OSLog
    ) -> T {
        let data: Data
        do {
            data = try loadJSON(resourceName)
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
