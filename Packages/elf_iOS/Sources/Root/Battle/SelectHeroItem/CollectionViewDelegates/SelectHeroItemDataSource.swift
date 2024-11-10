//
//  SelectHeroItemDataSource.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 20.10.24.
//

import Combine
import elf_Kit
import UIKit

internal final class SelectHeroItemDataSource {
    
    internal let emptyCellUUID = UUID()
    
    private let collectionView: UICollectionView
    private lazy var dataSource: UICollectionViewDiffableDataSource<Int, UUID> = configureDataSource()
    private let viewModel: SelectHeroItemViewModel
    private var heroItemDictionary: [UUID: Item] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    init(collectionView: UICollectionView, viewModel: SelectHeroItemViewModel) {
        self.collectionView = collectionView
        self.viewModel = viewModel
        setupBindings()
    }
    
    internal var hasItems: Bool {
        return !dataSource.snapshot().itemIdentifiers.isEmpty
    }
    
    internal var hasOnlyEmptyCell: Bool {
        return dataSource.snapshot().numberOfItems == 1 && dataSource.snapshot().itemIdentifiers.first == emptyCellUUID
    }
    
    internal func itemIdentifier(for indexPath: IndexPath) -> UUID? {
        return dataSource.itemIdentifier(for: indexPath) ?? nil
    }
    
    internal func indexOfItem(with id: UUID) -> Int? {
        guard let snapshot = dataSource.snapshot().itemIdentifiers.firstIndex(of: id) else {
            return nil
        }
        return snapshot
    }
    
    private func configureDataSource() -> UICollectionViewDiffableDataSource<Int, UUID> {
        return UICollectionViewDiffableDataSource<Int, UUID>(collectionView: collectionView) { collectionView, indexPath, itemIdentifier in
            if itemIdentifier == self.emptyCellUUID {
                // Вернуть пустую ячейку
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: EmptyHeroItemCollectionViewCell.reuseIdentifier, for: indexPath) as? EmptyHeroItemCollectionViewCell else {
                    assertionFailure("Failed to dequeue EmptyHeroItemCollectionViewCell")
                    return nil
                }
                return cell
            } else {
                // Вернуть обычную ячейку
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HeroItemCollectionViewCell.reuseIdentifier, for: indexPath) as? HeroItemCollectionViewCell,
                      let heroItem = self.heroItemDictionary[itemIdentifier] else {
                    assertionFailure("Failed to dequeue HeroItemCollectionViewCell or find corresponding hero item")
                    return nil
                }
                
                cell.itemTitleLabel.text = heroItem.title
                cell.itemImageView.image = UIImage(named: "card_\(heroItem.id.uuidString.lowercased())")
                return cell
            }
        }
    }

    
    private func setupBindings() {
        viewModel.$heroItems
            .receive(on: DispatchQueue.main)
            .sink { [weak self] heroItems in
                self?.updateDataSource(with: heroItems)
            }
            .store(in: &cancellables)
    }
    
    private func updateDataSource(with heroItems: HeroItems?) {
        var itemIDs: [UUID] = []
        
        // Добавляем фиктивный UUID для пустой ячейки в начало
        itemIDs.append(emptyCellUUID)
        
        guard let heroItems = heroItems else {
            heroItemDictionary.removeAll()
            applySnapshot(with: itemIDs)
            return
        }
        
        let filteredItems = viewModel.filterItems(for: viewModel.heroItemType, in: heroItems)
        
        heroItemDictionary = filteredItems.reduce(into: [:]) { $0[$1.id] = $1 }
        
        itemIDs.append(contentsOf: filteredItems.map { $0.id })
        
        applySnapshot(with: itemIDs)
    }
    
    private func applySnapshot(with itemIDs: [UUID]) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, UUID>()
        snapshot.appendSections([0])
        snapshot.appendItems(itemIDs, toSection: 0)
        
        // Отключить анимацию, если snapshot пуст
        let animate = !itemIDs.isEmpty
        dataSource.apply(snapshot, animatingDifferences: animate) { [weak self] in
            self?.selectInitialItem()
        }
    }
    
    internal func selectInitialItem() {
        guard hasItems else { return }
        
        // Определяем начальный индекс для выделения
        let initialIndexPath: IndexPath
        if let currentHeroItemId = viewModel.currentHeroItemId,
           let itemIndex = indexOfItem(with: currentHeroItemId) {
            // Если есть текущий itemId, то выбираем соответствующую ячейку
            initialIndexPath = IndexPath(item: itemIndex, section: 0)
        } else {
            // Если currentHeroItemId == nil, выбираем первую ячейку (EmptyHeroItemCollectionViewCell)
            initialIndexPath = IndexPath(item: 0, section: 0)
        }
        
        // Проверяем, что индекс находится в допустимых пределах
        if initialIndexPath.item < collectionView.numberOfItems(inSection: 0) {
            collectionView.selectItem(at: initialIndexPath, animated: true, scrollPosition: .centeredHorizontally)
            collectionView.delegate?.collectionView?(collectionView, didSelectItemAt: initialIndexPath)
        }
    }
}
