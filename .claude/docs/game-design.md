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

## Fishing System

Fishing is a skill-based activity at the Lake that provides magical crafting materials.

### Mechanics

| Parameter | Value |
|-----------|-------|
| **Cost** | 20 Action Points per attempt |
| **Max Catch** | Up to 4 fish per attempt |
| **Catch Method** | Each fish has independent probability check |

### Fish Tiers

| Tier | Catch Chance | XP Reward | Examples |
|------|--------------|-----------|----------|
| **Common** | 30-35% | 5 XP | Silverscale Minnow, Moonpearl Carp |
| **Uncommon** | 20-25% | 8 XP | Crimson Flicker, Frostfin Trout |
| **Rare** | 10-15% | 12 XP | Thundertail, Shadowgill |
| **Legendary** | 5% | 20 XP | Spirit Koi, Venomspine Eel |

### Fish Effects (8 types)

Fish provide magical essences used in crafting:

| Effect | Description |
|--------|-------------|
| **Arcane** | Pure magical energy |
| **Flame** | Fire magic essence |
| **Frost** | Ice magic essence |
| **Storm** | Lightning/wind essence |
| **Shadow** | Dark magic essence |
| **Radiance** | Light magic essence |
| **Spirit** | Spiritual energy |
| **Venom** | Poison magic essence |

### Skill Progression

- **50 XP per level** for fishing skill
- Higher skill levels may unlock better fishing spots (future feature)

---

## Herb Gathering System

Herb gathering is a skill-based activity in the Forest that provides potion crafting materials.

### Mechanics

| Parameter | Value |
|-----------|-------|
| **Cost** | 20 Action Points per attempt |
| **Max Gather** | Up to 4 herbs per attempt |
| **Gather Method** | Each herb has independent probability check |

### Herb Tiers

| Tier | Gather Chance | XP Reward | Examples |
|------|---------------|-----------|----------|
| **Common** | 30-35% | 5 XP | Sunpetal, Moonbloom, Greenleaf, Ironroot |
| **Uncommon** | 18-20% | 8 XP | Bloodberry, Swiftgrass, Bitterleaf |
| **Rare** | 10% | 12 XP | Starbloom, Firethorn |
| **Legendary** | 5% | 20 XP | Dragonheart, Ethereal Lily |

### Herb Effects (8 types)

Herbs provide essences used in potion crafting:

| Effect | Description |
|--------|-------------|
| **Healing** | Restores health |
| **Stamina** | Restores energy |
| **Strength** | Increases attack power |
| **Defense** | Increases protection |
| **Speed** | Increases agility |
| **Antidote** | Cures poison |
| **Luck** | Increases luck |
| **Mana** | Restores magic |

### Skill Progression

- **50 XP per level** for herb gathering skill
- Higher skill levels may unlock rarer herb spots (future feature)

---

## Ore Mining System

Ore mining is a skill-based activity in the Mountains that provides crafting materials for weapons and armor.

### Mechanics

| Parameter | Value |
|-----------|-------|
| **Cost** | 20 Action Points per attempt |
| **Max Mine** | Up to 4 ores per attempt |
| **Mine Method** | Each ore has independent probability check |

### Ore Tiers

| Tier | Mine Chance | XP Reward | Examples |
|------|-------------|-----------|----------|
| **Common** | 30-35% | 5 XP | Copper Chunk, Iron Shard, Bronze Ore |
| **Uncommon** | 18-20% | 8 XP | Silver Ore, Coal Crystal, Quartz Shard |
| **Rare** | 10% | 12 XP | Gold Nugget, Mithril Fragment |
| **Legendary** | 5% | 20 XP | Adamantite Core |

### Ore Usage

Ores are primary materials for crafting equipment:

| Ore Type | Crafting Use |
|----------|--------------|
| **Copper, Iron, Bronze** | Basic weapons and armor (Tier 4) |
| **Silver, Coal, Quartz** | Enhanced equipment (Tier 3) |
| **Gold, Mithril** | Rare equipment (Tier 2) |
| **Adamantite** | Legendary equipment (Tier 1) |

*Note: Currently, ores do not have magical effects - they are purely crafting materials. Special ores with unique properties may be added in future updates.*

### Skill Progression

- **50 XP per level** for mining skill
- Higher skill levels may unlock richer ore veins (future feature)

---

## Farm Activity Hazards

All farm activities (hunting, gathering, mining, fishing) carry risk of monster encounters.

### Monster Attacks

| Parameter | Value |
|-----------|-------|
| **Attack Chance** | 20% per activity |
| **Battle Type** | 1v1 combat |
| **Monster Level** | Scaled (max level 3) |

### Mechanics

- Monster attack interrupts the current activity
- Player must defeat the monster before continuing
- Standard combat rules apply
- Rewards from the interrupted activity are still received if monster is defeated

---

## Character Attributes

See **[`attributes.md`](attributes.md)** — single source of truth for the
attribute roster, fight styles, per-level scaling, the style triangle
(`def > dodge > crit > def`), and the planned Endurance / EP system.

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
