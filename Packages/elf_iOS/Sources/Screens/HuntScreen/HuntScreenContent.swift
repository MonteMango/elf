//
//  HuntScreenContent.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 08.12.25.
//

import elf_Kit
import elf_SwiftUI
import SwiftUI

struct HuntScreenContent: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel: HuntViewModel

    init(viewModel: HuntViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack {
            // Background
            HuntConstants.Colors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar: Back button + Action Points
                topBar
                    .padding(.top, HuntConstants.Spacing.topPadding)
                    .padding(.horizontal, HuntConstants.Spacing.horizontalPadding)

                Spacer()

                // Monster collection
                monsterCollection

                Spacer()

                // Hunt button
                huntButton
                    .padding(.bottom, HuntConstants.Spacing.sectionSpacing)
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Top Bar

    @ViewBuilder
    private var topBar: some View {
        HStack {
            // Back button
            BackButton {
                router.pop()
            }

            Spacer()

            // Action Points Bar
            ActionPointsBar(
                current: viewModel.currentActionPoints,
                max: viewModel.maxActionPoints,
                label: "Action points",
                barHeight: HuntConstants.Sizing.apBarHeight,
                labelFont: HuntConstants.Fonts.apLabel,
                barFont: HuntConstants.Fonts.apValue,
                labelColor: .gray,
                fillColor: HuntConstants.Colors.apBarFill,
                backgroundColor: HuntConstants.Colors.apBarBackground,
                showNextDayButton: true,
                isLastDay: viewModel.isLastDay,
                onNextDay: { viewModel.advanceToNextDay() }
            )
            .frame(width: HuntConstants.Sizing.apBarWidth)

            Spacer()

            // Empty space for symmetry
            Color.clear
                .frame(width: 44, height: 44)
        }
    }

    // MARK: - Monster Collection

    @ViewBuilder
    private var monsterCollection: some View {
        HStack(spacing: HuntConstants.Spacing.monsterSpacing) {
            ForEach(viewModel.availableMonstersDisplayData) { displayData in
                MonsterCell(displayData: displayData)
            }
        }
        .padding(.horizontal, HuntConstants.Spacing.horizontalPadding)
    }

    // MARK: - Hunt Button

    @ViewBuilder
    private var huntButton: some View {
        Button("Hunt") {
            Task {
                if let battle = await viewModel.startHunt() {
                    router.navigationPath.append(AppRoute.battleFight(battle))
                }
            }
        }
        .buttonStyle(.elfPrimary(isEnabled: viewModel.canHunt))
        .disabled(!viewModel.canHunt)
        .overlay(alignment: .bottomTrailing) {
            Text("\(viewModel.huntCost) pt")
                .font(.footnote)
                .foregroundColor(.white.opacity(0.7))
                .padding(4)
        }
    }
}

#Preview {
    @Previewable @State var router = AppRouter()

    HuntScreenContent(
        viewModel: HuntViewModel(
            gameService: PreviewMockData.createMockGameService(),
            monsterRepository: ElfMonsterRepository(),
            materialRepository: ElfMaterialRepository(),
            snapshotBuilder: PreviewMockData.createMockSnapshotBuilder()
        )
    )
    .environment(router)
}
