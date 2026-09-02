# Granny-clicker — кликер для Яндекс Игр (Godot 4.7)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

2D-кликер: кликаем по бабушке → монеты → апгрейды (сила клика + пассивный
доход). Полная интеграция с Яндекс Играми: сохранения в облако через Player
API, rewarded- и fullscreen-реклама, статусы LoadingAPI / GameplayAPI.

## Возможности

- Кликер с прогрессией (сила клика, пассивный доход, криты, авто-кликер).
- **Паутина (web trap)** — кнопка baby_of_slenderine: бабка в паутине на
  15 сек, ×2 ко всему доходу, но апгрейды/дед/реклама/ачивки/перерождение
  заблокированы. Кулдаун 20 сек.
- **Бешеный дедушка (frenzy)** — ×2.5 к кликам на 8 сек, кулдаун 30 сек.
- **Казино-медвежонок (teddy)** — чёт/нечёт: ×1.5 или −50% монет.
- Дополнительные персонажи: Робот (авто-кликер) и Анжела (случайный бонус).
- Смена фона после перерождения (fon_1..fon_5).
- Престиж (сброс прогресса с бонусом), достижения.
- Интеграция с Яндекс Играми: облачные сейвы, реклама за бонусы,
  корректные loading/gameplay-статусы.
- Сворачиваемая правая панель апгрейдов.
- Офлайн-режим: на ПК без Яндекса игра через локальный фолбэк-сейв.

## Управление

- **ЛКМ по бабушке** — клик (монеты).
- **Паутина ×2** — web trap: ×2 ко всему доходу на 15 сек.
- **Бешеный дедушка** — ×2.5 к кликам на 8 сек.
- **Реклама: x2 монет** — rewarded-видео за бонус.
- **Казино-медвежонок** — чёт/нечёт ставка.
- **Полноэкранный режим** — кнопка выхода в полный экран (где доступно).

## Требования

- Godot Engine **4.7** (stable) с установленными экспортными шаблонами.
- Для Web-сборки — шаблон Web.
- Для Android-сборки — Android SDK/NDK + `export_presets.cfg`
  (локально, в `.gitignore`; см. ниже) и keystore.

## Структура проекта

```
project.godot                 имя Granny Clicker, автолоады GameState / YandexSDK
icon.png                      иконка проекта и boot-splash
prev.png                      сплэш-экран
scenes/main.tscn              главная сцена (UI строится в scripts/main.gd)
scripts/main.gd               сборка UI, таймеры, связка систем
scripts/game_state.gd         состояние, прогрессия, сейв/логика
scripts/yandex_sdk.gd         мост GDScript <-> window.__yandex (Web) и Android-плагин
scripts/ads.gd                контроллер рекламы и экранов загрузки
scripts/audio_manager.gd      звуки кликов/покупок
scripts/ui_theme.gd           тема UI (стили кнопок, шрифты)
scripts/ui/fx.gd              визуальные эффекты (тряска, кровь, вспышки)
scripts/ui/hud.gd             монеты, доход/сек, ачивки
scripts/ui/upgrades.gd        кнопки апгрейдов
scripts/ui/frenzy.gd          бешеный дедушка
scripts/ui/web_button.gd      паутина (web trap)
scripts/ui/teddy.gd           казино-медвежонок
scripts/ui/angela.gd          Анжела (случайный бонус)
scripts/ui/robot.gd           Робот (авто-кликер)
scripts/ui/prestige.gd        перерождение
scripts/ui/achievements.gd    ачивки
scripts/ui/settings.gd        настройки
scripts/ui/loc.gd             локализация (ru/en)
assets/                       спрайты: granny_button/, angela.png,
                              teddy.png, baby_of_slenderine.png, web.png,
                              robot.png, coin.png, fons/fon_1..5.png и др.
addons/yandex_mobile_ads/     плагин Яндекс Мобайл Адс (Android)
export_presets.cfg           пресеты экспорта (локально, в .gitignore — содержит секрет keystore)
```

> Папки `build/`, `android/` и `.godot/` находятся в `.gitignore` и **не
> попадают в репозиторий** (содержат собранные артефакты и кэш редактора).

## Запуск в редакторе (ПК)

1. Открой `project.godot` в Godot 4.7.
2. Нажми Run. Без Яндекс SDK игра работает в офлайн-режиме: сейвы пишутся
   в `user://meme_click_save.json`, реклама имитируется.

## Экспорт и публикация Web-версии (Яндекс Игры)

Сборка выполняется в `build/web/`, затем архивируется в ZIP для загрузки:

```bash
godot --headless --export-release "Web" build/web/index.html
cd build/web && zip -r ../meme_click_yandex.zip .
```

Залей `build/meme_click_yandex.zip` в кабинет разработчика Яндекс Игр.

Интеграция с SDK реализована через `html/head_include` в пресете экспорта:
подключается локальный `sdk.js` (лежит рядом с игрой в `build/web/`) и
создаётся `window.__yandex` (init / getData / setData / showFullscreen /
showRewarded / gameplayStart / gameplayStop / LoadingAPI.ready). Из GDScript
всё идёт через `JavaScriptBridge.get_interface("__yandex")` + `create_callback`.

## Экспорт Android

Пресет `Android` настраивается локально в `export_presets.cfg` (этот файл
намеренно **не коммитится** — в нём лежит пароль keystore). Для сборки
своего APK создай собственный keystore и заполни поля в `export_presets.cfg`.

```bash
godot --headless --export-release "Android" build/android/meme_click.apk
```

## Лицензия

Проект распространяется под лицензией **MIT** — см. файл [LICENSE](LICENSE).
