extends StaticBody2D

## Новогодний шар - разбивается от подарка/ёлки
## Без штрафа очков

signal destroyed

var ball_color: Color = Color.RED

func _ready():
	add_to_group("blocker")
	var colors = [
		Color(0.9, 0.15, 0.15),
		Color(0.15, 0.5, 0.9),
		Color(0.9, 0.75, 0.1),
		Color(0.15, 0.8, 0.3),
		Color(0.7, 0.2, 0.8),
	]
	ball_color = colors.pick_random()
	_update_color()
	
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(self, "rotation_degrees", 5, 0.6).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "rotation_degrees", -5, 0.6).set_trans(Tween.TRANS_SINE)

func _update_color():
	if has_node("Visual/Ball"):
		$Visual/Ball.color = ball_color
	if has_node("Visual/Highlight1"):
		$Visual/Highlight1.color = ball_color.lightened(0.4)
		$Visual/Highlight1.color.a = 0.5

func on_gift_hit(is_star_gift: bool = false):
	# Даём небольшое количество очков за сбитие шарика
	GameManager.add_score(25, global_position)
	emit_signal("destroyed")
	SoundManager.play_sound("ornament_break")
	_destroy_effect()
	queue_free()

func on_hit():
	# От ёлки
	emit_signal("destroyed")
	SoundManager.play_sound("ornament_break")
	_destroy_effect()
	queue_free()

func _destroy_effect():
	var parent = get_parent()
	if not parent:
		return
	
	for i in range(12):
		var shard = ColorRect.new()
		shard.size = Vector2(randf_range(6, 14), randf_range(6, 14))
		shard.color = ball_color
		if randf() < 0.3:
			shard.color = ball_color.lightened(0.5)
		shard.global_position = global_position
		parent.get_parent().add_child(shard)
		
		var angle = randf() * TAU
		var speed = randf_range(100, 200)
		var target = global_position + Vector2(cos(angle), sin(angle)) * speed
		target.y += randf_range(20, 60)
		
		var tween = shard.create_tween()
		tween.set_parallel(true)
		tween.tween_property(shard, "global_position", target, 0.5)
		tween.tween_property(shard, "rotation", randf_range(-6, 6), 0.5)
		tween.tween_property(shard, "modulate:a", 0.0, 0.5)
		tween.set_parallel(false)
		tween.tween_callback(shard.queue_free)
	
	for i in range(8):
		var sparkle = ColorRect.new()
		sparkle.size = Vector2(4, 4)
		sparkle.color = Color(1, 1, 1, 0.9)
		sparkle.global_position = global_position + Vector2(randf_range(-15, 15), randf_range(-15, 15))
		parent.get_parent().add_child(sparkle)
		
		var tween = sparkle.create_tween()
		tween.tween_property(sparkle, "modulate:a", 0.0, 0.3)
		tween.tween_callback(sparkle.queue_free)
