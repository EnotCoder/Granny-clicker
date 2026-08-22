# Granny-clicker — кликер для Яндекс Игр (Godot 4.7)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Простой 2D-кликер: кликаем по мемe (бабушке) → монеты → апгрейды
(сила клика + пассивный доход). Полная интеграция с Яндекс Играми:
сохранения в облако через Player API, rewarded- и fullscreen-реклама,
статусы LoadingAPI / GameplayAPI.

## Возможности

- Кликер с прогрессией (сила клика, пассивный доход, криты).
- Дополнительные персонажи: Робот и Анжела (событийные механики).
- Престиж (сброс прогресса с бонусом), достижения, таймеры/ивенты (Frenzy).
- Интеграция с Яндекс Играми: облачные сейвы, реклама за бонусы,
  корректные loading/gameplay-статусы.
- Офлайн-режим: на ПК без Яндекса играетя через локальный фолбэк-сейв.

## Управление

- **ЛКМ по мемe** — клик (монеты).
- **Реклама: x2 монет** — rewarded-видео за бонус.
- **Полноэкранный режим** — кнопка выхода в полный экран (где доступно).

## Требования

- Godot Engine **4.7** (stable) с установленными экспортными шаблонами.
- Для Web-сборки — шаблон Web.
- Для Android-сборки — Android SDK/NDK + `export_presets.cfg`
  (локально, в `.gitignore`; см. ниже) и keystore.

## Структура проекта

```
project.godot                 имя meme_click, автолоады GameState / YandexSDK
icon.png                      иконка проекта и boot-splash
scenes/main.tscn              главная сцена (UI строится в scripts/main.gd)
scripts/main.gd               сборка UI, таймеры, связка систем
scripts/game_state.gd         состояние, прогрессия, сейв/логика
scripts/yandex_sdk.gd         мост GDScript <-> window.__yandex (Web) и Android-плагин
scripts/ads.gd                контроллер рекламы и экранов загрузки
scripts/ui/fx.gd              визуальные эффекты (тряска, кровь, вспышки)
assets/                       спрайты: granny_button/, robot.png, angela.png,
                               fon.png, fon_1.png, coin.png, ring.png, settings.png
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
