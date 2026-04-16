//
//  PerfTestConfig.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov
//

import Foundation

/// Tuneables for the dev-only Battle performance test screens.
///
/// Edit these to change the scale/shape of the multi-battle simulation run.
/// The default `1000` lives inside `MultiBattleViewModel`; this config overrides
/// it at the container level so the perf screen runs a larger, more meaningful
/// workload.
public enum PerfTestConfig {

    /// Number of battles simulated per `MultiBattleResultScreen` run.
    /// 30_000 is the largest value that fits in memory without OOM on iPhone —
    /// each `BattleResult` carries a full `roundHistory` and per-round stats.
    public static let multiBattleCount: Int = 30_000
}
