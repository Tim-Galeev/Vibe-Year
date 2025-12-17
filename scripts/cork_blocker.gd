extends StaticBody2D

## Пробка от шампанского - затыкает дымоход

signal destroyed

func _ready():
	add_to_group("blocker")

func on_hit():
	GameManager.add_score(50)
	emit_signal("destroyed")
	print("🍾 Пробка выбита! +50")
	_destroy_effect()
	queue_free()

func _destroy_effect():
	var parent = get_parent()
	if not parent:
		return
	
	# Пробка вылетает вверх
	var cork = ColorRect.new()
	cork.size = Vector2(20, 30)
	cork.color = Color(0.6, 0.45, 0.25)
	cork.global_position = global_position
	parent.get_parent().add_child(cork)
	
	var tween = cork.create_tween()
	tween.set_parallel(true)
	tween.tween_property(cork, "global_position:y", cork.global_position.y - 150, 0.5)
	tween.tween_property(cork, "global_position:x", cork.global_position.x + randf_range(-50, 50), 0.5)
	tween.tween_property(cork, "rotation", randf_range(-6, 6), 0.5)
	tween.set_parallel(false)
	tween.tween_property(cork, "modulate:a", 0.0, 0.3)
	tween.tween_callback(cork.queue_free)
	
	# Брызги шампанского
	for i in range(12):
		var bubble = ColorRect.new()
		bubble.size = Vector2(randf_range(4, 10), randf_range(4, 10))
		bubble.color = Color(1, 0.95, 0.7, 0.8)
		bubble.global_position = global_position
		parent.get_parent().add_child(bubble)
		
		var angle = randf_range(-PI * 0.8, -PI * 0.2)  # Вверх и в стороны
		var speed = randf_range(80, 180)
		var target = global_position + Vector2(cos(angle), sin(angle)) * speed
		
		var bubble_tween = bubble.create_tween()
		bubble_tween.set_parallel(true)
		bubble_tween.tween_property(bubble, "global_position", target, 0.5)
		bubble_tween.tween_property(bubble, "modulate:a", 0.0, 0.5)
		bubble_tween.set_parallel(false)
		bubble_tween.tween_callback(bubble.queue_free)
