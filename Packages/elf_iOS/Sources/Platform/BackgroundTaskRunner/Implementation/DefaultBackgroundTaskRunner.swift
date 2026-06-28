//
//  DefaultBackgroundTaskRunner.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import UIKit

/// `UIApplication`-backed `BackgroundTaskRunner`. Stateless — each `run` owns its
/// own assertion id, so concurrent calls never share or clobber state.
struct DefaultBackgroundTaskRunner: BackgroundTaskRunner {

    @MainActor
    func run(name: String, _ work: @escaping @MainActor () async -> Void) {
        let app = UIApplication.shared
        var taskID: UIBackgroundTaskIdentifier = .invalid
        // Acquire synchronously, before the async hop below — this is what keeps the
        // process alive past the ~5s suspension window.
        taskID = app.beginBackgroundTask(withName: name) {
            // Time expired — end the assertion to avoid a 0x8badf00d watchdog kill.
            app.endBackgroundTask(taskID)
            taskID = .invalid
        }

        Task { @MainActor in
            await work()
            // Skip if the expiration handler already ended it (taskID == .invalid).
            if taskID != .invalid {
                app.endBackgroundTask(taskID)
                taskID = .invalid
            }
        }
    }
}
