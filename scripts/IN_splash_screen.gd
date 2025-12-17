extends Control

## Заставка при запуске - показывает лого и переходит к игре

@export var display_time: float = 2.5
@export var fade_time: float = 0.5
@export var next_scene: String = "res://scenes/game.tscn"

func _ready():
	# Начинаем с прозрачности
	modulate.a = 0
	
	# Анимация появления
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, fade_time)
	tween.tween_interval(display_time)
	tween.tween_property(self, "modulate:a", 0.0, fade_time)
	tween.tween_callback(_go_to_next_scene)

func _input(event):
	# Пропуск заставки по любой клавише/клику
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton:
		if event.pressed:
			_go_to_next_scene()

func _go_to_next_scene():
	get_tree().change_scene_to_file(next_scene)
