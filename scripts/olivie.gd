extends Area2D

## Оливье - замедляет карту, съедает подарки

signal hit_by_sleigh

func _ready():
	add_to_group("obstacle")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("sleigh"):
		_affect_sleigh(body)

func _affect_sleigh(sleigh):
	emit_signal("hit_by_sleigh")
	GameManager.activate_slow()
	
	if sleigh.has_method("take_damage"):
		sleigh.take_damage(1)
	if sleigh.has_method("hit_obstacle"):
		sleigh.hit_obstacle()

func on_gift_hit(gift):
	# Подарок застревает - просто эффект
	SoundManager.play_sound("damage")
	_create_sink_effect(gift.global_position)

func _create_sink_effect(pos: Vector2):
	var parent = get_parent()
	if not parent:
		return
	
	for i in range(6):
		var piece = ColorRect.new()
		piece.size = Vector2(8, 8)
		piece.color = [Color(0.85, 0.88, 0.7), Color(1, 0.55, 0.2), Color(0.35, 0.65, 0.3)].pick_random()
		piece.global_position = pos
		parent.add_child(piece)
		
		var tween = piece.create_tween()
		var target = pos + Vector2(randf_range(-40, 40), randf_range(-60, -20))
		tween.set_parallel(true)
		tween.tween_property(piece, "global_position", target, 0.4)
		tween.tween_property(piece, "modulate:a", 0.0, 0.4)
		tween.set_parallel(false)
		tween.tween_callback(piece.queue_free)

func on_hit():
	GameManager.add_score(10, global_position)
	_destroy_effect()
	queue_free()

func _destroy_effect():
	var parent = get_parent()
	if not parent:
		return
	
	for i in range(10):
		var piece = ColorRect.new()
		piece.size = Vector2(12, 12)
		piece.color = [Color(0.85, 0.88, 0.7), Color(1, 0.55, 0.2), Color(0.35, 0.65, 0.3), Color(0.98, 0.97, 0.9)].pick_random()
		piece.global_position = global_position + Vector2(randf_range(-20, 20), randf_range(-10, 10))
		parent.add_child(piece)
		
		var tween = piece.create_tween()
		var target = piece.global_position + Vector2(randf_range(-60, 60), randf_range(-80, -20))
		tween.set_parallel(true)
		tween.tween_property(piece, "global_position", target, 0.5)
		tween.tween_property(piece, "rotation", randf_range(-4, 4), 0.5)
		tween.tween_property(piece, "modulate:a", 0.0, 0.5)
		tween.set_parallel(false)
		tween.tween_callback(piece.queue_free)
