//
//  RootViewModelTests.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 12.07.25.
//

import XCTest
import Combine
@testable import elf_Kit

final class RootViewModelTests: XCTestCase {
    private var viewModel: RootViewModel!
    private var fakeRepository: FakeItemsRepository!
    private var cancellables: Set<AnyCancellable> = []

    override func setUp() {
        super.setUp()
        fakeRepository = FakeItemsRepository()
        viewModel = RootViewModel(itemsRepository: fakeRepository)
    }

    override func tearDown() {
        viewModel = nil
        fakeRepository = nil
        cancellables.removeAll()
        super.tearDown()
    }

    func testInitialStateIsMenu() {
        XCTAssertEqual(viewModel.viewState, .menu)
    }

    func testSetViewStateChangesState() {
        viewModel.setViewState(.battle)
        XCTAssertEqual(viewModel.viewState, .battle)
    }
}

final class FakeItemsRepository: ItemsRepository {
    var heroItems: HeroItems? = nil
    
    var heroItemsPublisher: AnyPublisher<HeroItems?, Never> {
        Just(heroItems).eraseToAnyPublisher()
    }

    func loadHeroItems() async throws {
        return // можно дополнить, если понадобится
    }

    func getHeroItem(_ id: UUID) async -> Item? {
        return nil // можно дополнить, если понадобится
    }
}
