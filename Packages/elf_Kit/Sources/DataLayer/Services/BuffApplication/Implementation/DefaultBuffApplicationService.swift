//
//  DefaultBuffApplicationService.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies
import Foundation

public final class DefaultBuffApplicationService: BuffApplicationService {

    private let buffsRepository: any BuffsRepository

    public init() {
        @Dependency(\.buffsRepository) var buffsRepository
        self.buffsRepository = buffsRepository
    }

    public func applyAsGlobal(
        buffId: BuffID,
        to buffs: [AppliedBuff],
        currentDay: Int
    ) -> [AppliedBuff] {
        applyCore(buffId: buffId, to: buffs, currentDay: currentDay, expectedScope: .global)
    }

    public func applyAsBattle(
        buffId: BuffID,
        to buffs: [AppliedBuff]
    ) -> [AppliedBuff] {
        applyCore(buffId: buffId, to: buffs, currentDay: nil, expectedScope: .battle)
    }

    private func applyCore(
        buffId: BuffID,
        to buffs: [AppliedBuff],
        currentDay: Int?,
        expectedScope: BuffScope
    ) -> [AppliedBuff] {
        guard let buff = buffsRepository.getById(id: buffId) else { return buffs }
        guard buff.scope == expectedScope else {
            assertionFailure("apply called with \(expectedScope) but buff \(buffId) has scope \(buff.scope)")
            return buffs
        }

        var updated = buffs
        if let index = updated.firstIndex(where: { $0.buffId == buffId }) {
            switch buff.stackingRule {
            case .refresh:
                updated[index].appliedOnDay = currentDay
            case .stack:
                updated[index].stacks += 1
                updated[index].appliedOnDay = currentDay
            case .ignore:
                break
            }
        } else {
            updated.append(AppliedBuff(buffId: buffId, appliedOnDay: currentDay))
        }
        return updated
    }
}
