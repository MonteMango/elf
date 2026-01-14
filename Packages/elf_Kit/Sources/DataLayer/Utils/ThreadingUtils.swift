//
//  ThreadingUtils.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 14.01.26.
//

import Foundation

// MARK: - Thread Assertions

/// Asserts that the current code is NOT running on the main thread.
/// Use this in heavy computations to catch accidental main thread execution during development.
///
/// Example:
/// ```swift
/// func calculateBattleResult() {
///     assertNotMainThread("Battle calculation should run on background thread")
///     // heavy computation...
/// }
/// ```
@inlinable
public func assertNotMainThread(_ message: @autoclosure () -> String = "Heavy operation should not run on main thread") {
    #if DEBUG
    assert(!Thread.isMainThread, message())
    #endif
}

/// Asserts that the current code IS running on the main thread.
/// Use this for UI operations that must happen on the main thread.
///
/// Example:
/// ```swift
/// func updateUI() {
///     assertMainThread("UI updates must happen on main thread")
///     label.text = "Updated"
/// }
/// ```
@inlinable
public func assertMainThread(_ message: @autoclosure () -> String = "UI operation must run on main thread") {
    #if DEBUG
    assert(Thread.isMainThread, message())
    #endif
}

// MARK: - Thread Info (Debug Only)

#if DEBUG
/// Returns current thread information for debugging purposes.
/// Only available in DEBUG builds.
public func currentThreadInfo() -> String {
    let thread = Thread.current
    let isMain = thread.isMainThread
    let name = thread.name ?? "unnamed"
    return "Thread: \(name), isMain: \(isMain)"
}
#endif
