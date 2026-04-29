//
//  AutoBattleResultScreen.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 19.11.25.
//

import elf_Kit
import SwiftUI

internal struct AutoBattleResultScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: AutoBattleViewModel

    internal init(battle: Battle) {
        self._viewModel = State(initialValue: AutoBattleViewModel(battle: battle))
    }

    internal var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        ZStack {
            Color.black.ignoresSafeArea()

            if viewModel.isRunning {
                progressView
            } else if let result = viewModel.result {
                resultView(result)
            }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            await viewModel.runAutoBattle()
        }
    }

    // MARK: - Progress View

    private var progressView: some View {
        VStack(spacing: 20) {
            Text("Battle in Progress")
                .font(.title)
                .bold()
                .foregroundStyle(.white)

            ProgressView(value: viewModel.progress)
                .progressViewStyle(.linear)
                .frame(width: 300)
                .tint(.green)

            Text("\(Int(viewModel.progress * 100))%")
                .font(.headline)
                .foregroundStyle(.white)
        }
    }

    // MARK: - Result View

    private func resultView(_ result: BattleResult) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                headerView
                winnerSection(result)
                actionButtons
                statisticsSection(result)
                roundHistorySection(result)
            }
            .padding(.top, 16)
        }
    }

    private var headerView: some View {
        HStack {
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.gray.opacity(0.3))
                    .clipShape(Circle())
            }
            .padding(.trailing, 16)
        }
    }

    private func winnerSection(_ result: BattleResult) -> some View {
        VStack(spacing: 12) {
            Text(result.winner == .left ? "Bot1 Wins!" : "Bot2 Wins!")
                .font(.largeTitle)
                .bold()
                .foregroundStyle(result.winner == .left ? .green : .red)

            HStack(spacing: 40) {
                botHPView(
                    name: "Bot1",
                    hp: result.bot1FinalHP,
                    isWinner: result.winner == .left
                )

                Text("vs")
                    .font(.title3)
                    .foregroundStyle(.gray)

                botHPView(
                    name: "Bot2",
                    hp: result.bot2FinalHP,
                    isWinner: result.winner == .right
                )
            }

            Text("Total Rounds: \(result.totalRounds)")
                .font(.subheadline)
                .foregroundStyle(.gray)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.1))
        )
        .padding(.horizontal)
    }

    private func botHPView(name: String, hp: Int, isWinner: Bool) -> some View {
        VStack {
            Text(name)
                .font(.headline)
                .foregroundStyle(.white)
            Text("\(hp) HP")
                .font(.title2)
                .foregroundStyle(isWinner ? .green : .gray)
        }
    }

    private func statisticsSection(_ result: BattleResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Battle Statistics")
                .font(.title2)
                .bold()
                .foregroundStyle(.white)
                .padding(.horizontal)

            StatisticsRow(
                title: "Critical Hit Rate",
                bot1Value: String(format: "%.1f%%", result.statistics.bot1CritRate * 100),
                bot2Value: String(format: "%.1f%%", result.statistics.bot2CritRate * 100)
            )

            StatisticsRow(
                title: "Critical Hits",
                bot1Value: "\(result.statistics.bot1CritSuccesses)/\(result.statistics.bot1CritAttempts)",
                bot2Value: "\(result.statistics.bot2CritSuccesses)/\(result.statistics.bot2CritAttempts)"
            )

            StatisticsRow(
                title: "Dodge Rate",
                bot1Value: String(format: "%.1f%%", result.statistics.bot1DodgeRate * 100),
                bot2Value: String(format: "%.1f%%", result.statistics.bot2DodgeRate * 100)
            )

            StatisticsRow(
                title: "Dodges",
                bot1Value: "\(result.statistics.bot1DodgeSuccesses)/\(result.statistics.bot1DodgeAttempts)",
                bot2Value: "\(result.statistics.bot2DodgeSuccesses)/\(result.statistics.bot2DodgeAttempts)"
            )

            StatisticsRow(
                title: "Total Damage",
                bot1Value: "\(result.statistics.bot1TotalDamage)",
                bot2Value: "\(result.statistics.bot2TotalDamage)"
            )

            StatisticsRow(
                title: "Avg Damage/Round",
                bot1Value: String(format: "%.1f", result.statistics.bot1AverageDamagePerRound),
                bot2Value: String(format: "%.1f", result.statistics.bot2AverageDamagePerRound)
            )

            StatisticsRow(
                title: "Total Strength Damage",
                bot1Value: "\(result.statistics.bot1TotalStrengthDamage)",
                bot2Value: "\(result.statistics.bot2TotalStrengthDamage)"
            )

            StatisticsRow(
                title: "Avg Strength Dmg/Round",
                bot1Value: String(format: "%.1f", result.statistics.bot1AverageStrengthDamagePerRound),
                bot2Value: String(format: "%.1f", result.statistics.bot2AverageStrengthDamagePerRound)
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.1))
        )
        .padding(.horizontal)
    }

    private func roundHistorySection(_ result: BattleResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Round History")
                .font(.title2)
                .bold()
                .foregroundStyle(.white)
                .padding(.horizontal)

            ForEach(result.roundHistory) { round in
                RoundHistoryRow(round: round)
            }
        }
        .padding(.horizontal)
    }

    private var actionButtons: some View {
        Button(action: {
            Task {
                await viewModel.runAutoBattle()
            }
        }) {
            Text("Fight Again")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue, in: RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 24)
    }
}
