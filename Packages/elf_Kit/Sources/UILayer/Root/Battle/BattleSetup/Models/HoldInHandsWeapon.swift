//
//  HoldInHandsWeapon.swift
//  elf_Kit
//
//  Created by Vitalii Lytvynov on 09.06.25.
//

public enum HoldInHandsWeapon {
    case noWeapon
    case twoHandsWeapon(twoHandsweapon: ElfWeaponItem)
    case leftPrimaryRightEmpty(primaryWeapon: ElfWeaponItem)
    case leftPrimaryRightShield(primaryWeapon: ElfWeaponItem, shield: ElfShieldItem)
    case leftSecondaryRightEmpty(secondaryWeapon: ElfWeaponItem)
    case leftEmptyRightSecondary(secondaryWeapon: ElfWeaponItem)
    case leftSecondaryRightSecondary(leftSecondaryWeapon: ElfWeaponItem, rightSecondaryWeapon: ElfWeaponItem)
    case leftSecondaryRightShield(secondaryWeapon: ElfWeaponItem, shield: ElfShieldItem)
    case leftEmptyRigthShield(shield: ElfShieldItem)
}
