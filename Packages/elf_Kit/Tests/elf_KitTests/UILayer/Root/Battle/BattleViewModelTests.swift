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
        viewModel.setViewState(.fight)
        XCTAssertEqual(viewModel.viewState, .fight)
    }

    func testPublishedViewStateEmitsOnChange() {
        let expectation = XCTestExpectation(description: "ViewState publisher emits value")

        var receivedStates: [BattleViewState] = []

        viewModel.$viewState
            .dropFirst() // пропускаем .setup
            .sink { state in
                receivedStates.append(state)
                if state == .fight {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        viewModel.setViewState(.fight)

        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(receivedStates, [.fight])
    }
}

