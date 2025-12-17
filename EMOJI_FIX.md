# Шрифты и эмодзи

## Что нужно сделать:

### 1. Скачать NotoSans-Regular.ttf

Скачай с Google Fonts:
https://fonts.google.com/noto/specimen/Noto+Sans

Нажми "Download family" → распакуй → возьми файл `NotoSans-Regular.ttf`

### 2. Положить в проект

Скопируй файл в: `fonts/NotoSans-Regular.ttf`

### 3. Перезапустить Godot

После добавления шрифта перезапусти редактор.

## Как это работает:

- `fonts/main_font.tres` — FontVariation с NotoSans + эмодзи fallback
- `theme.tres` — тема проекта с main_font
- `project.godot` → `gui/theme/custom` → использует тему

## Структура шрифтов:

```
fonts/
  NotoSans-Regular.ttf      ← СКАЧАТЬ!
  main_font.tres            ← FontVariation (NotoSans + emoji fallback)

addons/icons-fonts/icons_fonts/emojis/
  NotoColorEmoji.ttf        ← Эмодзи шрифт (из плагина)
```

## HUD выравнивание:

Все элементы CenterHUD теперь имеют:
- `custom_minimum_size = Vector2(0, 50)` — одинаковая высота
- `size_flags_vertical = 4` — CENTER
- `vertical_alignment = 1` — CENTER
