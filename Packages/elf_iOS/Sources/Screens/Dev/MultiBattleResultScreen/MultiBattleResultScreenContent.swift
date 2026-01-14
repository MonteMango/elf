//
//  MultiBattleResultScreenContent.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 21.11.25.
//

import elf_Kit
import SwiftUI

internal struct MultiBattleResultScreenContent: View {
    @State private var viewModel: ElfAppDependencyContainer.MultiBattleVM
    let onClose: () -> Void

    internal init(
        viewModel: ElfAppDependencyContainer.MultiBattleVM,
        onClose: @escaping () -> Void
    ) {
        self._viewModel = State(initialValue: viewModel)
        self.onClose = onClose
    }

    internal var body: some View {
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
            await viewModel.runAllBattles()
        }
    }

    // MARK: - Progress View

    private var progressView: some View {
        VStack(spacing: 20) {
            Text("Running 1000 Battles")
                .font(.title)
                .bold()
                .foregroundColor(.white)

            ProgressView(value: viewModel.progress)
                .progressViewStyle(.linear)
                .frame(width: 300)
                .tint(.green)

            Text("\(viewModel.completedBattles)/\(viewModel.totalBattles) battles")
                .font(.headline)
                .foregroundColor(.white)
        }
    }

    // MARK: - Result View

    private func resultView(_ result: MultiBattleResult) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                headerView
                winRatesSection(result)
                actionButtons
                bot1StatisticsSection(result)
                bot2StatisticsSection(result)
            }
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
    }

    private var headerView: some View {
        HStack {
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.gray.opacity(0.3))
                    .clipShape(Circle())
            }
            .padding(.trailing, 16)
        }
    }

    // MARK: - Win Rates Section

    private func winRatesSection(_ result: MultiBattleResult) -> some View {
        VStack(spacing: 16) {
            Text("1000 Battle Results")
                .font(.largeTitle)
                .bold()
                .foregroundColor(.white)

            HStack(spacing: 20) {
                winRateBox(
                    title: "Bot1",
                    subtitle: "Lv.\(result.bot1Level)",
                    wins: result.bot1Wins,
                    rate: result.bot1WinRate,
                    color: .green
                )

                winRateBox(
                    title: "Draw",
                    subtitle: "Both KO",
                    wins: result.draws,
                    rate: result.drawRate,
                    color: .gray
                )

                winRateBox(
                    title: "Bot2",
                    subtitle: "Lv.\(result.bot2Level)",
                    wins: result.bot2Wins,
                    rate: result.bot2WinRate,
                    color: .red
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.1))
        )
        .padding(.horizontal)
    }

    private func winRateBox(
        title: String,
        subtitle: String,
        wins: Int,
        rate: Double,
        color: Color
    ) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)

            Text(subtitle)
                .font(.caption)
                .foregroundColor(.gray)

            Text("\(wins)")
                .font(.title)
                .bold()
                .foregroundColor(color)

            Text(String(format: "%.1f%%", rate * 100))
                .font(.subheadline)
                .foregroundColor(color.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        Button(action: {
            viewModel.reset()
            Task {
                await viewModel.runAllBattles()
            }
        }) {
            Text("Fight Again")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Bot1 Statistics Section

    private func bot1StatisticsSection(_ result: MultiBattleResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Bot1 Statistics (Lv.\(result.bot1Level))")
                .font(.title2)
                .bold()
                .foregroundColor(.green)
                .padding(.horizontal)

            statisticsContent(result.bot1AggregatedStats)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.1))
        )
        .padding(.horizontal)
    }

    // MARK: - Bot2 Statistics Section

    private func bot2StatisticsSection(_ result: MultiBattleResult) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Bot2 Statistics (Lv.\(result.bot2Level))")
                .font(.title2)
                .bold()
                .foregroundColor(.red)
                .padding(.horizontal)

            statisticsContent(result.bot2AggregatedStats)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.1))
        )
        .padding(.horizontal)
    }

    // MARK: - Statistics Content

    private func statisticsContent(_ stats: AggregatedBattleStatistics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            statRow(title: "Avg Rounds", value: String(format: "%.1f", stats.averageRounds))

            Divider().background(Color.gray.opacity(0.3))

            statRow(title: "Crit Rate", value: String(format: "%.1f%%", stats.averageCritRate * 100))
            statRow(title: "Avg Crit Hits", value: String(format: "%.1f", stats.averageCritHits))
            statRow(
                title: "Total Crits",
                value: "\(stats.totalCritSuccesses)/\(stats.totalCritAttempts)"
            )

            Divider().background(Color.gray.opacity(0.3))

            statRow(title: "Dodge Rate", value: String(format: "%.1f%%", stats.averageDodgeRate * 100))
            statRow(title: "Avg Dodges", value: String(format: "%.1f", stats.averageDodges))
            statRow(
                title: "Total Dodges",
                value: "\(stats.totalDodgeSuccesses)/\(stats.totalDodgeAttempts)"
            )

            Divider().background(Color.gray.opacity(0.3))

            statRow(title: "Avg Total Damage", value: String(format: "%.0f", stats.averageTotalDamage))
            statRow(title: "Avg Damage/Round", value: String(format: "%.1f", stats.averageDamagePerRound))

            Divider().background(Color.gray.opacity(0.3))

            statRow(title: "Avg Strength Dmg", value: String(format: "%.0f", stats.averageStrengthDamage))
            statRow(title: "Avg Str Dmg/Round", value: String(format: "%.1f", stats.averageStrengthDamagePerRound))
        }
        .padding(.horizontal)
    }

    private func statRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)

            Spacer()

            Text(value)
                .font(.headline)
                .foregroundColor(.white)
        }
    }
}
