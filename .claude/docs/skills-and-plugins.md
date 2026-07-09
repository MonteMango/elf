# Skills & Plugins — что подключено в проекте

Справка по всем скилам, плагинам и командам, доступным Claude Code в проекте Elfy.
Сведения физически разнесены по нескольким механизмам (см. ниже) — этот файл собирает их в одну картину.

> Обновлять этот файл при подключении/отключении скилов вручную — Claude Code его не генерирует.
> Актуально на: sdd 1.16.0, swiftui-expert 4.0.0, swift-concurrency 2.1.1.

---

## TL;DR — реестр

| Что | Тип | Уровень | Версия | Автообновление |
|---|---|---|---|---|
| **sdd** (пакет из ~19 скилов + агенты + MCP) | плагин | глобальный | 1.16.0 | ✅ |
| **swiftui-expert** | плагин | проектный | 4.0.0 | ✅ |
| **swift-concurrency** | плагин | проектный | 2.1.1 | ✅ |
| **swift-testing-expert** | плагин | проектный | 1.2.0 | ✅ |
| **rocketsim** | плагин | проектный | 1.0.0 | ✅ |
| **swift-lsp** | плагин | глобальный | 1.0.0 | ❌ (ручное) |
| **swiftui-performance-audit** | standalone-скил | проектный | — | ❌ (переустановка) |
| **leonardo-ai-prompts** | локальный скил | проектный | — | — (свой файл) |
| build / lint / test / review / new-screen | команды | проектный | — | — (свои файлы) |
| ~20 resume/career скилов | плагин `career-ops` | глобальный | 1.6.0 | ⛔ выключены |

---

## 1. Плагины из маркетплейсов

Плагин = пакет из GitHub-репозитория, может нести сразу много скилов, агентов и даже MCP-сервер.
Включаются через `enabledPlugins`, источник — через `extraKnownMarketplaces`.

### Проектные (только для Elfy) — `.claude/settings.json`

| Плагин | Репозиторий | Что даёт |
|---|---|---|
| `swiftui-expert` | `AvdLee/SwiftUI-Agent-Skill` | ревью/рефакторинг SwiftUI, `@Observable`, производительность вью, Liquid Glass |
| `swift-concurrency` | `AvdLee/Swift-Concurrency-Agent-Skill` | async/await, actors, Sendable, миграция на Swift 6 |
| `swift-testing-expert` | `AvdLee/Swift-Testing-Agent-Skill` | Swift Testing: `#expect`/`#require`, трейты, параметризация |
| `rocketsim` | `AvdLee/RocketSim-Agent-Skill` | управление iOS-симулятором через RocketSim CLI |

### Глобальные (во всех проектах) — `~/.claude/settings.json`

| Плагин | Репозиторий | Что даёт |
|---|---|---|
| `sdd` | `genkovich/sdd` | Spec-Driven Development: весь набор `sdd:*` (см. ниже) + агенты + дашборд + MCP-сервер |
| `swift-lsp` | `anthropics/claude-plugins-official` | Swift Language Server (навигация/диагностика по коду) |
| `career-ops` | локальная директория | ~20 скилов для резюме — **выключены** через `skillOverrides` в проекте |

### Скилы внутри плагина `sdd`

Один плагин sdd несёт целый пайплайн Spec-Driven Development. Скилы вызываются как `sdd:<name>`:

```
survey · glossary · roadmap · interview · specify · clarify · classify-size
design · sequences · decide-adr · data-model · api · plan-tests · tasks
implement · fix · review · ship · start
```

Плюс sdd приносит агентов (`sdd:analyst`, `sdd:critic`, `sdd:reviewer`, `sdd:explorer`,
`sdd:implementer`, `sdd:test-author`, …) и MCP-сервер дашборда.
Локальная конфигурация дашборда/пайплайна лежит в `.claude/sdd.local.md`.

---

## 2. Standalone-скилы (не плагины)

Устанавливаются по одному прямо в `.claude/skills/` (симлинком на `.agents/skills/`).
Отслеживаются lock-файлом `skills-lock.json` в корне проекта (источник + хэш содержимого).

| Скил | Источник | Назначение |
|---|---|---|
| `swiftui-performance-audit` | `dimillian/skills` (GitHub) | аудит рантайм-производительности SwiftUI по коду + гайд для Instruments |

> `.agents/` в `.gitignore` — физические файлы скила в репо не попадают.
> `skills-lock.json` **закоммичен** и остаётся единственной записью о том, какой внешний скил
> и откуда восстанавливать. **Не автообновляется** — обновление = переустановка из источника
> (тогда пересчитается `computedHash` в lock-файле).

---

## 3. Локальные скилы (свои)

Лежат в `.claude/skills/` как обычные файлы, нигде не «объявляются», версий/источника нет.

| Скил | Назначение |
|---|---|
| `leonardo-ai-prompts` | генерация промптов для арта игры (портреты, фоны, иконки) через Leonardo AI |

---

## 4. Проектные slash-команды — `.claude/commands/`

Не скилы, а короткие команды-обёртки, специфичные для Elfy:

| Команда | Что делает |
|---|---|
| `/build` | сборка проекта под iOS Simulator |
| `/lint` | запуск SwiftLint |
| `/test` | юнит-тесты пакета `elf_Kit` |
| `/review` | ревью текущих git-изменений |
| `/new-screen` | новый экран по single-file Screen pattern + swift-dependencies |

---

## Где что настраивается (карта файлов)

| Файл | За что отвечает |
|---|---|
| `.claude/settings.json` | проектные плагины (`enabledPlugins` / `extraKnownMarketplaces`), отключения (`skillOverrides`) |
| `~/.claude/settings.json` | глобальные плагины (sdd, swift-lsp, career-ops) |
| `~/.claude/plugins/known_marketplaces.json` | рантайм-реестр маркетплейсов (кэш; флаги `autoUpdate` синхронизируются сюда) |
| `~/.claude/plugins/cache/` | распакованные версии установленных плагинов |
| `skills-lock.json` | «пломба» standalone-скилов (источник + хэш) |
| `.claude/skills/` | симлинки standalone/локальных скилов |
| `.agents/skills/` | физические файлы этих скилов (в `.gitignore`) |
| `.claude/commands/` | проектные slash-команды |

---

## Обновление

- **Автообновляемые** (`sdd`, `swiftui-expert`, `swift-concurrency`, `swift-testing-expert`,
  `rocketsim`): подтягиваются сами при старте сессии, когда в репо-источнике выходит новая версия.
- **Ручные** (`swift-lsp`, `swiftui-performance-audit`): обновлять через `/plugin` → Update
  либо переустановкой скила из источника.
- Форсировать проверку плагина раньше: `/plugin` → выбрать плагин → Update.

---

*Created by Vitalii Lytvynov*
