//
//  RoomBattleRewardMutator+Dependency.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov
//

import Dependencies

extension DependencyValues {
    public var roomBattleRewardMutator: any RoomBattleRewardMutator {
        get { self[RoomBattleRewardMutatorKey.self] }
        set { self[RoomBattleRewardMutatorKey.self] = newValue }
    }
}

private enum RoomBattleRewardMutatorKey: DependencyKey {
    static var liveValue: any RoomBattleRewardMutator { DefaultRoomBattleRewardMutator() }
    static var testValue: any RoomBattleRewardMutator { liveValue }
}
