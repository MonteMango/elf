# Elfy - Game Design Document

## Project Overview

**Elfy** is a turn-based tactical RPG for iOS where players control an elf girl competing in a tournament between 8 Houses. The game combines character customization, resource management, strategic combat, and house-based competition.

---

## Core Gameplay Loop

### Character Creation
- Customize appearance
- Choose name
- Select combat style

### House Assignment
- Player is randomly assigned to one of **8 Houses**
- Each House contains **10 elves** (player + 9 AI companions)
- Houses compete throughout the game until one remains victorious

### Daily Action System
- Game progresses through a **calendar system**
- Each day grants a limited number of **Action Points (AP)**
- Player chooses how to spend AP on various activities
- Day ends when all AP are spent

---

## Day Types

| Day Type | Description |
|----------|-------------|
| **Normal Day** | Spend AP on hunting monsters, gathering herbs, mining ore, or fishing |
| **Dungeon Day** | Two groups of 5 elves each venture into different dungeons. Fight monsters and a dungeon boss for unique rewards |
| **Random Event Day** | A random event occurs affecting gameplay |
| **House War Day** | **Main progression event.** Houses battle each other in elimination matches until one House remains. Game ends when a winner is determined |

---

## Activities (Normal Days)

| Activity | Location | Rewards |
|----------|----------|---------|
| Monster Hunting | Various | XP, loot drops |
| Herb Gathering | Forest | Crafting materials |
| Ore Mining | Mountains | Crafting materials |
| Fishing | Lake | Crafting materials |

*Materials are used for crafting items and artifacts.*

---

## Character Attributes

All combat entities (elves, monsters, etc.) have the following stats:

| Attribute | Effect |
|-----------|--------|
| **Strength** | Increases damage dealt |
| **Agility** | Dodge chance; reduces enemy critical damage multiplier |
| **Power** | Critical hit chance (crits pierce blocks) |
| **Intuition** | Reduces enemy dodge chance; reduces enemy crit chance |
| **Health Points (HP)** | Survivability; reaches 0 = defeat |
| **Mana Points (MP)** | Resource for abilities (future implementation) |

---

## Equipment System

### Equipment Slots (11 total)

| Slot | Category |
|------|----------|
| Head | Armor |
| Upper Body | Armor |
| Undershirt | Armor |
| Lower Body | Armor |
| Hands | Armor |
| Legs | Armor |
| Left Hand | Weapon/Shield |
| Right Hand | Weapon/Shield |
| Ring | Accessory |
| Earrings | Accessory |
| Necklace | Accessory |

### Equipment Effects
- **Stat bonuses** — Increase character attributes
- **Armor value** — Reduces incoming damage

---

## Combat System

### Turn-Based Tactical Combat

Combat is divided into **rounds**. Each round:

1. **Select attack target(s)** — Choose body part(s) to strike
2. **Select block target(s)** — Choose body part(s) to defend
3. **Confirm** — Both sides reveal choices simultaneously
4. **Resolution** — Calculate hits, blocks, dodges, and crits

### Target Zones (5 total)
```
        [Head]
[Left Arm]  [Torso]  [Right Arm]
        [Legs]
```

### Attack & Block Points

| Loadout | Attack Points | Block Points |
|---------|---------------|--------------|
| Default | 1 | 2 |
| With Shield | 1 | 3 |
| Dual Wield | 2 | 2 |

### Combat Resolution

1. **Hit Check** — Did attacker target an unblocked zone?
2. **Dodge Check** — Defender's Agility vs Attacker's Intuition
3. **Critical Check** — Attacker's Power vs Defender's Intuition
4. **Damage Calculation** — Apply Strength, Armor, and multipliers

### Special Mechanics

- **Dodge** — Chance to completely avoid an attack (based on Agility)
- **Critical Hit** — Pierces blocks and applies damage multiplier (based on Power)
- **Block** — Negates normal attacks to protected zones

### Victory Conditions

- Reduce opponent's HP to 0 → **Victory**
- Your HP reaches 0 → **Defeat**
- Both reach 0 simultaneously → **Draw**
