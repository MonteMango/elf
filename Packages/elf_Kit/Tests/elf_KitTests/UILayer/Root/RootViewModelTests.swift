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

    func testLoadHeroItemsCallsRepositoryOffMainThread() async throws {
        viewModel.loadHeroItems()

        try await XCTAssertEventually(self.fakeRepository.didCallLoadHeroItems)

        XCTAssertFalse(
            fakeRepository.wasCalledOnMainThread,
            "Метод loadHeroItems() должен вызываться не на главном потоке"
        )
    }
}

final class FakeItemsRepository: ItemsRepository {
    var heroItems: HeroItems? = nil
    
    private(set) var didCallLoadHeroItems = false
    private(set) var wasCalledOnMainThread = false
    
    var heroItemsPublisher: AnyPublisher<HeroItems?, Never> {
        Just(heroItems).eraseToAnyPublisher()
    }

    func loadHeroItems() async throws {
        try await Task.sleep(nanoseconds: 50_000_000) // Эмуляция задержки
        didCallLoadHeroItems = true
        wasCalledOnMainThread = DispatchQueue.isMain
    }

    func getHeroItem(_ id: UUID) async -> Item? {
        return nil // можно дополнить, если понадобится
    }
}

func XCTAssertEventually(
    _ expression: @autoclosure @escaping () -> Bool,
    timeout: TimeInterval = 1.0,
    interval: TimeInterval = 0.01,
    file: StaticString = #file,
    line: UInt = #line
) async throws {
    let start = Date()
    while Date().timeIntervalSince(start) < timeout {
        if expression() {
            return
        }
        try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
    }
    XCTFail("Условие не выполнено за \(timeout) секунд", file: file, line: line)
}

extension DispatchQueue {
    static var isMain: Bool {
        let key = DispatchSpecificKey<String>()
        let value = "main"
        DispatchQueue.main.setSpecific(key: key, value: value)
        return DispatchQueue.getSpecific(key: key) == value
    }
}
