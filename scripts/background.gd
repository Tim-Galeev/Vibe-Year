extends Node2D

## Фон - ночное небо со звёздами

@onready var stars_container: Node2D = $Stars
@onready var sky: ColorRect = $Sky

func _ready():
	_update_sky_size()
	_generate_stars()
	# Подписываемся на изменение размера окна
	get_tree().root.size_changed.connect(_on_viewport_size_changed)

func _on_viewport_size_changed():
	_update_sky_size()

func _update_sky_size():
	if sky:
		var viewport_size = get_viewport_rect().size
		sky.size = viewport_size

func _generate_stars():
	if not stars_container:
		return
	
	# Создаём много звёзд
	for i in range(100):
		var star = ColorRect.new()
		var size = randf_range(1, 4)
		star.size = Vector2(size, size)
		star.position = Vector2(
			randf_range(0, 1280),
			randf_range(0, 400)  # Только в верхней части неба
		)
		
		# Разные оттенки звёзд
		var brightness = randf_range(0.5, 1.0)
		if randf() < 0.1:
			star.color = Color(1, 0.9, 0.7, brightness)  # Жёлтые
		elif randf() < 0.1:
			star.color = Color(0.8, 0.9, 1, brightness)  # Голубые
		else:
			star.color = Color(brightness, brightness, brightness, brightness)
		
		stars_container.add_child(star)
		
		# Анимация мерцания для некоторых звёзд
		if randf() < 0.3:
			var tween = create_tween()
			tween.set_loops()
			var delay = randf_range(0, 2)
			tween.tween_interval(delay)
			tween.tween_property(star, "modulate:a", randf_range(0.3, 0.6), randf_range(0.5, 1.5))
			tween.tween_property(star, "modulate:a", 1.0, randf_range(0.5, 1.5))
