//
//  FakeWeaponValidator.swift
//  elf_KitTests
//
//  Created by Vitalii Lytvynov
//

import Foundation
@testable import elf_Kit

/// Controllable `WeaponValidator` test double. Each `validateAndResolve` call
/// suspends on its own continuation instead of resolving immediately or after
/// a `Task.sleep` — a test releases calls one at a time, in whatever order it
/// chooses, each with the exact result that call should produce. This lets a
/// test reproduce rapid re-selection races deterministically: the *first*
/// validation to be called can be made to resolve *after* a later one.
actor FakeWeaponValidator: WeaponValidator {

    /// A call currently suspended, awaiting `release(at:with:)`.
    struct PendingCall {
        let itemId: ItemID?
        let slot: HeroItemType
        let currentItems: [HeroItemType: ItemID?]
    }

    private struct Entry {
        let call: PendingCall
        let continuation: CheckedContinuation<[HeroItemType: ItemID?], Never>
    }

    private var entries: [Entry] = []
    private var waiters: [(count: Int, continuation: CheckedContinuation<Void, Never>)] = []

    /// Calls currently suspended, oldest first — inspect to decide which index
    /// to release and with what result.
    var pendingCalls: [PendingCall] {
        entries.map(\.call)
    }

    func validateAndResolve(
        selecting itemId: ItemID?,
        for slot: HeroItemType,
        currentItems: [HeroItemType: ItemID?]
    ) async -> [HeroItemType: ItemID?] {
        await withCheckedContinuation { continuation in
            entries.append(Entry(
                call: PendingCall(itemId: itemId, slot: slot, currentItems: currentItems),
                continuation: continuation
            ))
            resumeSatisfiedWaiters()
        }
    }

    /// Suspends until at least `count` calls are registered — the test's
    /// synchronization point to know a call has actually reached its `await`
    /// before releasing anything, so releasing never races the ViewModel's
    /// own `Task` scheduling.
    func waitUntilPending(_ count: Int) async {
        guard entries.count < count else { return }
        await withCheckedContinuation { continuation in
            waiters.append((count, continuation))
        }
    }

    /// Releases the call at `index` (in arrival order), resuming its
    /// `validateAndResolve` await with `result`.
    func release(at index: Int, with result: [HeroItemType: ItemID?]) {
        let entry = entries.remove(at: index)
        entry.continuation.resume(returning: result)
    }

    private func resumeSatisfiedWaiters() {
        waiters.removeAll { waiter in
            guard entries.count >= waiter.count else { return false }
            waiter.continuation.resume()
            return true
        }
    }
}
