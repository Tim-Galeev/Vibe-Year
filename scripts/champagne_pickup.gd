extends Area2D

## Шампанское - ускоряет карту

signal collected

func _ready():
	add_to_group("pickup")
	body_entered.connect(_on_body_entered)
	
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(self, "position:y", position.y - 10, 0.8).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "position:y", position.y + 10, 0.8).set_trans(Tween.TRANS_SINE)

func _on_body_entered(body):
	if body.is_in_group("sleigh"):
		_collect()

func _collect():
	GameManager.add_champagne(global_position)
	emit_signal("collected")
	SoundManager.play_sound("pickup")
	
	_create_bubble_effect()
	_animate_collect()

func collect_by_gift():
	_collect()

func collect_by_tree():
	_collect()

func _animate_collect():
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.1)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(queue_free)

func _create_bubble_effect():
	var parent = get_parent()
	if not parent:
		return
	
	for i in range(8):
		var bubble = ColorRect.new()
		bubble.size = Vector2(randf_range(6, 12), randf_range(6, 12))
		bubble.color = Color(1, 1, 0.8, 0.7)
		bubble.global_position = global_position + Vector2(randf_range(-15, 15), 0)
		parent.add_child(bubble)
		
		var target_y = global_position.y - randf_range(60, 100)
		var target_x = global_position.x + randf_range(-25, 25)
		
		var tween = bubble.create_tween()
		tween.set_parallel(true)
		tween.tween_property(bubble, "global_position", Vector2(target_x, target_y), 0.6)
		tween.tween_property(bubble, "modulate:a", 0.0, 0.6)
		tween.set_parallel(false)
		tween.tween_callback(bubble.queue_free)
