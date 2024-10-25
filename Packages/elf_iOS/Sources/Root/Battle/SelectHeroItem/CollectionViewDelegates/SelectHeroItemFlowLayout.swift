
//
//  SelectHeroItemFlowLayout.swift
//  elf_iOS
//
//  Created by Vitalii Lytvynov on 21.10.24.
//

import elf_Kit
import UIKit

internal final class SelectHeroItemFlowLayout: NSObject, UICollectionViewDelegateFlowLayout {
    
    private var viewModel: SelectHeroItemViewModel
    private var dataSource: SelectHeroItemDataSource
    
    internal init(viewModel: SelectHeroItemViewModel, dataSource: SelectHeroItemDataSource) {
        self.viewModel = viewModel
        self.dataSource = dataSource
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 150, height: collectionView.bounds.height - 40)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 20
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 20
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Настроить состояние выделения для любой ячейки
        if let cell = collectionView.cellForItem(at: indexPath) {
            configureSelectedState(for: cell, isSelected: true)
        }
        
        // Проверить, если в коллекции только одна ячейка и её идентификатор равен emptyCellUUID
        guard !dataSource.hasOnlyEmptyCell else { return }
        
        // Получить идентификатор элемента, проверяя, не является ли он пустым
        let itemId = dataSource.itemIdentifier(for: indexPath) == dataSource.emptyCellUUID ? nil : dataSource.itemIdentifier(for: indexPath)
        
        // Сообщить viewModel о выбранном элементе
        viewModel.didSelectItem(at: indexPath, itemId: itemId)
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) {
            configureSelectedState(for: cell, isSelected: false)
        }
    }
    
    private func configureSelectedState(for cell: UICollectionViewCell, isSelected: Bool) {
        if isSelected {
            cell.layer.borderWidth = 2.0
            cell.layer.borderColor = UIColor.systemBlue.cgColor
        } else {
            cell.layer.borderWidth = 0.0
            cell.layer.borderColor = UIColor.clear.cgColor
        }
    }
}
