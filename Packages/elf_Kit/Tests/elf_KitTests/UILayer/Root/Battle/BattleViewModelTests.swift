//
//  BattleViewModelTests.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 12.07.25.
//

import XCTest
import Combine
@testable import elf_Kit

final class BattleViewModelTests: XCTestCase {
    private var viewModel: BattleViewModel!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        viewModel = BattleViewModel()
        cancellables = []
    }

    override func tearDown() {
        viewModel = nil
        cancellables = nil
        super.tearDown()
    }

    func testInitialStateIsSetup() {
        XCTAssertEqual(viewModel.viewState, .setup)
    }

    func testSetViewStateUpdatesState() {
        let userHero = HeroConfiguration()
        let enemyHero = HeroConfiguration()
        viewModel.setViewState(.fight(user: userHero, enemy: enemyHero))

        if case .fight = viewModel.viewState {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected viewState to be .fight")
        }
    }

    func testPublishedViewStateEmitsOnChange() {
        let expectation = XCTestExpectation(description: "ViewState publisher emits value")

        var receivedStates: [BattleViewState] = []

        viewModel.$viewState
            .dropFirst() // пропускаем .setup
            .sink { state in
                receivedStates.append(state)
                if case .fight = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        let userHero = HeroConfiguration()
        let enemyHero = HeroConfiguration()
        viewModel.setViewState(.fight(user: userHero, enemy: enemyHero))

        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(receivedStates.count, 1)
        if case .fight = receivedStates.first {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected first received state to be .fight")
        }
    }
}

