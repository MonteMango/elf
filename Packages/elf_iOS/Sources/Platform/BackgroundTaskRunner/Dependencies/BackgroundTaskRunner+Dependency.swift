//
//  BackgroundTaskRunner+Dependency.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    var backgroundTaskRunner: any BackgroundTaskRunner {
        get { self[BackgroundTaskRunnerKey.self] }
        set { self[BackgroundTaskRunnerKey.self] = newValue }
    }
}

private enum BackgroundTaskRunnerKey: DependencyKey {
    static var liveValue: any BackgroundTaskRunner { DefaultBackgroundTaskRunner() }
}
