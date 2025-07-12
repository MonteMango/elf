//
//  MenuViewModelTests.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 12.07.25.
//

import XCTest
@testable import elf_Kit

final class MenuViewModelTests: XCTestCase {

    final class FakeViewStateDelegate: ViewStateDelegate {
        typealias ViewStateType = RootViewState
        var lastSetState: RootViewState?

        func setViewState(_ state: RootViewState) {
            lastSetState = state
        }
    }

    func testFightButtonAction_setsBattleState() {
        // Подготовка
        let fakeDelegate = FakeViewStateDelegate()
        let anyDelegate = AnyViewStateDelegate(fakeDelegate)
        let viewModel = MenuViewModel(rootViewStateDelegate: anyDelegate)

        // Действие
        viewModel.fightButtonAction()

        // Проверка
        XCTAssertEqual(fakeDelegate.lastSetState, .battle)
    }
}

