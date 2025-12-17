# Система заставок (Splash Screens)

## Текущие заставки

### 1. Boot Splash (лого Godot)
- Настраивается в: Project Settings → Application → Boot Splash
- Можно заменить на свою картинку
- Показывается пока движок загружается

### 2. Заставка игры (SplashScreen)
- Файл: `scenes/splash_screen.tscn`
- Скрипт: `scripts/splash_screen.gd`
- Показывает лого игры и название
- Можно пропустить любой клавишей

## Как добавить ещё одну заставку

### Шаг 1: Создайте новую сцену заставки

Скопируйте `scenes/splash_screen.tscn` → `scenes/splash_screen_2.tscn`

Или создайте новую с таким содержимым:

```
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/splash_screen.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://your_logo.png" id="2_icon"]

[node name="SplashScreen2" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
script = ExtResource("1_script")
display_time = 2.0
fade_time = 0.5
next_scene = "res://scenes/game.tscn"

[node name="Background" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
color = Color(0, 0, 0, 1)

[node name="CenterContainer" type="CenterContainer" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0

[node name="Logo" type="TextureRect" parent="CenterContainer"]
custom_minimum_size = Vector2(300, 200)
layout_mode = 2
texture = ExtResource("2_icon")
expand_mode = 1
stretch_mode = 5
```

### Шаг 2: Настройте цепочку переходов

В **первой** заставке (`splash_screen.tscn`) измените `next_scene`:
```
next_scene = "res://scenes/splash_screen_2.tscn"
```

Во **второй** заставке укажите переход к игре:
```
next_scene = "res://scenes/game.tscn"
```

### Шаг 3: Параметры заставки

В инспекторе или в файле .tscn можно настроить:

- `display_time` — сколько секунд показывать (по умолчанию 2.5)
- `fade_time` — скорость появления/исчезновения (по умолчанию 0.5)
- `next_scene` — путь к следующей сцене

## Пример: Добавление заставки издателя

1. Создайте `scenes/publisher_splash.tscn`
2. Добавьте ваш логотип в проект (например `publisher_logo.png`)
3. Измените цепочку:
   - `project.godot` → `run/main_scene="res://scenes/publisher_splash.tscn"`
   - `publisher_splash.tscn` → `next_scene="res://scenes/splash_screen.tscn"`
   - `splash_screen.tscn` → `next_scene="res://scenes/game.tscn"`

## Отключение лого Godot

В Project Settings → Application → Boot Splash:
- `Show Image` = Off (отключить картинку)
- `Fullsize` = On (на весь экран)
- `Use Filter` = On (сглаживание)
- `Bg Color` = чёрный

**Внимание:** Полностью убрать Boot Splash нельзя, но можно сделать его чёрным и очень быстрым.

## Структура файлов

```
scenes/
  splash_screen.tscn      ← Заставка игры (первая)
  splash_screen_2.tscn    ← Ваша заставка (добавьте)
  game.tscn               ← Главная игра

scripts/
  splash_screen.gd        ← Универсальный скрипт заставки
```
