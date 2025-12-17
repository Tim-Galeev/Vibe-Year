extends StaticBody2D

## Мандарин-затычка - блокирует дымоход

signal destroyed

func _ready():
	add_to_group("blocker")

func on_hit():
	# Уничтожение от подарка или ёлки
	GameManager.add_score(50)
	emit_signal("destroyed")
	print("Мандарин-затычка уничтожена! +50")
	_destroy_effect()
	queue_free()

func _destroy_effect():
	var parent = get_parent()
	if not parent:
		return
	
	# Разлетающиеся кусочки мандарина
	for i in range(6):
		var piece = ColorRect.new()
		piece.size = Vector2(12, 12)
		piece.color = Color(1, 0.6, 0.1)
		piece.global_position = global_position
		parent.get_parent().add_child(piece)  # Добавляем в родителя крыши
		
		var tween = piece.create_tween()
		var target = global_position + Vector2(randf_range(-50, 50), randf_range(-70, -20))
		tween.set_parallel(true)
		tween.tween_property(piece, "global_position", target, 0.4)
		tween.tween_property(piece, "rotation", randf_range(-4, 4), 0.4)
		tween.tween_property(piece, "modulate:a", 0.0, 0.4)
		tween.set_parallel(false)
		tween.tween_callback(piece.queue_free)
