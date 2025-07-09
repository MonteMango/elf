//
//  BattleSetupViewController.swift
//  
//
//  Created by Vitalii Lytvynov on 28.08.24.
//

import Combine
import elf_Kit
import elf_UIKit
import Foundation
import UIKit

internal final class BattleSetupViewController: NiblessViewController {
   
    // MARK: Properties
    
    private let viewModel: BattleSetupViewModel
    private let screenView: BattleSetupScreenView
    
    private var cancellables = Set<AnyCancellable>()
    
    internal init(viewModel: BattleSetupViewModel) {
        self.viewModel = viewModel
        self.screenView = BattleSetupScreenView()
        super.init()
    }
    
    internal override func loadView() {
        super.loadView()
        view = screenView
    }
    
    internal override func viewDidLoad() {
        super.viewDidLoad()
        setupBindings()
        setupActions()
    }
    
    // MARK: Bindings
    
    private func setupBindings() {
        
        bindLevel(viewModel.playerHeroConfiguration.$level, to: screenView.userLevelView)
        bindLevel(viewModel.botHeroConfiguration.$level, to: screenView.botLevelView)
        
        bindAttributes(viewModel.playerHeroConfiguration, to: screenView.userAttributesView)
        bindAttributes(viewModel.botHeroConfiguration, to: screenView.botAttributesView)
        
        bindFightStyle(screenView.userSelectFightStyleStackView.selectFightStyleRadioButtonGroup, heroType: .player)
        bindFightStyle(screenView.botSelectFightStyleStackView.selectFightStyleRadioButtonGroup, heroType: .bot)
        
        bindItemImage(itemPublisher: viewModel.playerHeroConfiguration.items.$helmet, to: screenView.userHeroItemsView.helmetItemButton)
        bindItemImage(itemPublisher: viewModel.playerHeroConfiguration.items.$gloves, to: screenView.userHeroItemsView.glovesItemButton)
        bindItemImage(itemPublisher: viewModel.playerHeroConfiguration.items.$shoes, to: screenView.userHeroItemsView.shoesItemButton)
        bindItemImage(itemPublisher: viewModel.playerHeroConfiguration.items.$upperBody, to: screenView.userHeroItemsView.upperBodyItemButton)
        bindItemImage(itemPublisher: viewModel.playerHeroConfiguration.items.$bottomBody, to: screenView.userHeroItemsView.bottomBodyItemButton)
        bindItemImage(itemPublisher: viewModel.playerHeroConfiguration.items.$shirt, to: screenView.userHeroItemsView.shirtItemButton)
        bindItemImage(itemPublisher: viewModel.playerHeroConfiguration.items.$ring, to: screenView.userHeroItemsView.ringItemButton)
        bindItemImage(itemPublisher: viewModel.playerHeroConfiguration.items.$necklace, to: screenView.userHeroItemsView.necklaceItemButton)
        bindItemImage(itemPublisher: viewModel.playerHeroConfiguration.items.$earrings, to: screenView.userHeroItemsView.earringsItemButton)
        bindHandUse(viewModel.playerHeroConfiguration, attributesView: screenView.userAttributesView, heroItemsView: screenView.userHeroItemsView)
        
        bindItemImage(itemPublisher: viewModel.botHeroConfiguration.items.$helmet, to: screenView.botHeroItemsView.helmetItemButton)
        bindItemImage(itemPublisher: viewModel.botHeroConfiguration.items.$gloves, to: screenView.botHeroItemsView.glovesItemButton)
        bindItemImage(itemPublisher: viewModel.botHeroConfiguration.items.$shoes, to: screenView.botHeroItemsView.shoesItemButton)
        bindItemImage(itemPublisher: viewModel.botHeroConfiguration.items.$upperBody, to: screenView.botHeroItemsView.upperBodyItemButton)
        bindItemImage(itemPublisher: viewModel.botHeroConfiguration.items.$bottomBody, to: screenView.botHeroItemsView.bottomBodyItemButton)
        bindItemImage(itemPublisher: viewModel.botHeroConfiguration.items.$shirt, to: screenView.botHeroItemsView.shirtItemButton)
        bindItemImage(itemPublisher: viewModel.botHeroConfiguration.items.$ring, to: screenView.botHeroItemsView.ringItemButton)
        bindItemImage(itemPublisher: viewModel.botHeroConfiguration.items.$necklace, to: screenView.botHeroItemsView.necklaceItemButton)
        bindItemImage(itemPublisher: viewModel.botHeroConfiguration.items.$earrings, to: screenView.botHeroItemsView.earringsItemButton)
        bindHandUse(viewModel.botHeroConfiguration, attributesView: screenView.botAttributesView, heroItemsView: screenView.botHeroItemsView)
        
        bindArmor(configuration: viewModel.playerHeroConfiguration, armorView: screenView.userHeroItemsView.armorView)
        bindArmor(configuration: viewModel.botHeroConfiguration, armorView: screenView.botHeroItemsView.armorView)
    }
    
    private func bindLevel(_ publisher: Published<Int16>.Publisher, to levelView: HeroLevelView) {
        publisher
            .receive(on: DispatchQueue.main)
            .sink { level in
                levelView.updateLevelLabel(to: level)
            }
            .store(in: &cancellables)
    }
    
    private func bindAttributes(_ configuration: HeroConfiguration, to attributesView: AttributesView) {
        configuration.$fightStyleAttributes
            .combineLatest(configuration.$levelRandomAttributes, configuration.$itemsAttributes)
            .receive(on: DispatchQueue.main)
            .sink { fightStyleAttributes, levelRandomAttributes, itemsAttributes in
                attributesView.updateAttributes(
                    fightStyleAttributes: fightStyleAttributes,
                    levelRandomAttributes: levelRandomAttributes,
                    itemsAttributes: itemsAttributes
                )
            }
            .store(in: &cancellables)
    }
    
    private func bindFightStyle(_ radioButtonGroup: ElfRadioButtonGroup<SelectFightStyleRadioGroupState>, heroType: HeroType) {
        radioButtonGroup.$selectedValue
            .sink { [weak self] selectedFightStyle in
                guard let self = self else { return }
                self.viewModel.setHeroFightStyle(for: heroType, fightStyle: selectedFightStyle?.toFightStyle())
            }
            .store(in: &cancellables)
    }
    
    private func bindItemImage<T>(itemPublisher: Published<T?>.Publisher, to button: ElfButton) where T: ElfItem {
        itemPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak button] elfItem in
                guard let button = button else { return }
                if let id = elfItem?.item.id {
                    button.imageView?.image = UIImage(named: id.uuidString.lowercased())
                } else {
                    button.imageView?.image = nil
                }
            }
            .store(in: &cancellables)
    }
    
    private func bindArmor(configuration: HeroConfiguration, armorView: ArmorView) {
        configuration.$itemsArmor
            .receive(on: DispatchQueue.main)
            .sink { [weak armorView] itemsArmor in
                guard let armorView = armorView else { return }
                for (bodyPart, armor) in itemsArmor {
                    switch bodyPart {
                    case .head:
                        armorView.topArmorLabel.text = "\(armor)"
                    case .leftHand:
                        armorView.leftArmorLabel.text = "\(armor)"
                    case .body:
                        armorView.middleArmorLabel.text = "\(armor)"
                    case .rightHand:
                        armorView.rightArmorLabel.text = "\(armor)"
                    case .legs:
                        armorView.bottomArmorLabel.text = "\(armor)"
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func bindHandUse(_ configuration: HeroConfiguration, attributesView: AttributesView, heroItemsView: HeroItemsView) {
        configuration.items.$handsUse
            .receive(on: DispatchQueue.main)
            .sink { handUse in
                heroItemsView.weaponSecondaryFilterView.isHidden = true
                switch handUse {
                case .noWeapon:
                    attributesView.updateDamageAttributes(primaryMinDmg: 0, primaryMaxDmg: 0, secondaryMinDmg: 0, secondaryMaxDmg: 0)
                    heroItemsView.weaponPrimaryItemButton.imageView?.image = nil
                    heroItemsView.weaponScondaryItemButton.imageView?.image = nil
                case .twoHandsWeapon(let twoHandsweapon):
                    guard let weaponItem = twoHandsweapon.item as? WeaponItem else { return }
                    heroItemsView.weaponSecondaryFilterView.isHidden = false
                    heroItemsView.weaponPrimaryItemButton.imageView?.image = UIImage(named: weaponItem.id.uuidString.lowercased())
                    heroItemsView.weaponScondaryItemButton.imageView?.image = UIImage(named: weaponItem.id.uuidString.lowercased())
                    attributesView.updateDamageAttributes(primaryMinDmg: weaponItem.minimumAttackPoint, primaryMaxDmg: weaponItem.maximumAttackPoint, secondaryMinDmg: 0, secondaryMaxDmg: 0)
                case .leftEmptyRigthShield(let shield):
                    guard let shieldItem = shield.item as? ShieldItem else { return }
                    heroItemsView.weaponPrimaryItemButton.imageView?.image = nil
                    heroItemsView.weaponScondaryItemButton.imageView?.image = UIImage(named: shieldItem.id.uuidString.lowercased())
                    attributesView.updateDamageAttributes(primaryMinDmg: 0, primaryMaxDmg: 0, secondaryMinDmg: 0, secondaryMaxDmg: 0)
                case .leftEmptyRightSecondary(let secondaryWeapon):
                    guard let weaponItem = secondaryWeapon.item as? WeaponItem else { return }
                    heroItemsView.weaponPrimaryItemButton.imageView?.image = nil
                    heroItemsView.weaponScondaryItemButton.imageView?.image = UIImage(named: weaponItem.id.uuidString.lowercased())
                    attributesView.updateDamageAttributes(primaryMinDmg: 0, primaryMaxDmg: 0, secondaryMinDmg: weaponItem.minimumAttackPoint, secondaryMaxDmg: weaponItem.maximumAttackPoint)
                case .leftPrimaryRightEmpty(let primaryWeapon):
                    guard let weaponItem = primaryWeapon.item as? WeaponItem else { return }
                    heroItemsView.weaponPrimaryItemButton.imageView?.image = UIImage(named: weaponItem.id.uuidString.lowercased())
                    heroItemsView.weaponScondaryItemButton.imageView?.image = nil
                    attributesView.updateDamageAttributes(primaryMinDmg: weaponItem.minimumAttackPoint, primaryMaxDmg: weaponItem.maximumAttackPoint, secondaryMinDmg: 0, secondaryMaxDmg: 0)
                case .leftPrimaryRightShield(let primaryWeapon, let shield):
                    guard
                        let weaponItem = primaryWeapon.item as? WeaponItem,
                        let shieldItem = shield.item as? ShieldItem
                    else { return }
                    heroItemsView.weaponPrimaryItemButton.imageView?.image = UIImage(named: weaponItem.id.uuidString.lowercased())
                    heroItemsView.weaponScondaryItemButton.imageView?.image = UIImage(named: shieldItem.id.uuidString.lowercased())
                    attributesView.updateDamageAttributes(primaryMinDmg: weaponItem.minimumAttackPoint, primaryMaxDmg: weaponItem.maximumAttackPoint, secondaryMinDmg: 0, secondaryMaxDmg: 0)
                case .leftSecondaryRightEmpty(let secondaryWeapon):
                    guard let weaponItem = secondaryWeapon.item as? WeaponItem else { return }
                    heroItemsView.weaponPrimaryItemButton.imageView?.image = UIImage(named: weaponItem.id.uuidString.lowercased())
                    heroItemsView.weaponScondaryItemButton.imageView?.image = nil
                    attributesView.updateDamageAttributes(primaryMinDmg: weaponItem.minimumAttackPoint, primaryMaxDmg: weaponItem.maximumAttackPoint, secondaryMinDmg: 0, secondaryMaxDmg: 0)
                case .leftSecondaryRightShield(let secondaryWeapon, let shield):
                    guard
                        let weaponItem = secondaryWeapon.item as? WeaponItem,
                        let shieldItem = shield.item as? ShieldItem
                    else { return }
                    heroItemsView.weaponPrimaryItemButton.imageView?.image = UIImage(named: weaponItem.id.uuidString.lowercased())
                    heroItemsView.weaponScondaryItemButton.imageView?.image = UIImage(named: shieldItem.id.uuidString.lowercased())
                    attributesView.updateDamageAttributes(primaryMinDmg: weaponItem.minimumAttackPoint, primaryMaxDmg: weaponItem.maximumAttackPoint, secondaryMinDmg: 0, secondaryMaxDmg: 0)
                case .leftSecondaryRightSecondary(let leftSecondaryWeapon, let rightSecondaryWeapon):
                    guard
                        let leftWeaponItem = leftSecondaryWeapon.item as? WeaponItem,
                        let rightWeaponItem = rightSecondaryWeapon.item as? WeaponItem
                    else { return }
                    heroItemsView.weaponPrimaryItemButton.imageView?.image = UIImage(named: leftWeaponItem.id.uuidString.lowercased())
                    heroItemsView.weaponScondaryItemButton.imageView?.image = UIImage(named: rightWeaponItem.id.uuidString.lowercased())
                    attributesView.updateDamageAttributes(primaryMinDmg: leftWeaponItem.minimumAttackPoint, primaryMaxDmg: leftWeaponItem.maximumAttackPoint, secondaryMinDmg: rightWeaponItem.minimumAttackPoint, secondaryMaxDmg: rightWeaponItem.maximumAttackPoint)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: Actions
    
    private func setupActions() {
        screenView.closeButton.addTarget(viewModel, action: #selector(viewModel.closeButtonAction), for: .touchUpInside)
        
        setupLevelActions(for: screenView.userLevelView, heroType: .player)
        setupLevelActions(for: screenView.botLevelView, heroType: .bot)
        
        setupItemSelection(for: screenView.userHeroItemsView, heroType: .player)
        setupItemSelection(for: screenView.botHeroItemsView, heroType: .bot)
    }
    
    private func setupLevelActions(for levelView: HeroLevelView, heroType: HeroType) {
        levelView.increaseLevelAction = { [weak self] in
            self?.viewModel.changeLevel(heroType, increment: +1)
        }
        levelView.decreaseLevelAction = { [weak self] in
            self?.viewModel.changeLevel(heroType, increment: -1)
        }
    }
    
    private func setupItemSelection(for itemsView: HeroItemsView, heroType: HeroType) {
        itemsView.onItemSelected = { [weak self] heroItemButtonType in
            guard let heroItemType = self?.mapHeroItemButtonTypeToHeroItemType(heroItemButtonType) else { return }
            self?.viewModel.heroItemSelected(for: heroType, heroItemType: heroItemType)
        }
    }
    
    private func mapHeroItemButtonTypeToHeroItemType(_ buttonType: HeroItemButtonType) -> HeroItemType? {
        switch buttonType {
        case .helmet: return .helmet
        case .gloves: return .gloves
        case .shoes: return .shoes
        case .weaponPrimary: return .weapons
        case .weaponSecondary: return .shields
        case .upperBody: return .upperBody
        case .bottomBody: return .bottomBody
        case .shirt: return .shirt
        case .ring: return .ring
        case .necklace: return .necklace
        case .earrings: return .earrings
        }
    }
}

// MARK: - Extensions

extension SelectFightStyleRadioGroupState {
    func toFightStyle() -> FightStyle? {
        switch self {
        case .crit: return .crit
        case .dodge: return .dodge
        case .def: return .def
        }
    }
}
