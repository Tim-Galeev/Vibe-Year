extends Area2D

## Гора мандаринов - препятствие (старый файл, не используется)

signal hit_by_sleigh

func _ready():
	add_to_group("obstacle")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("sleigh"):
		_affect_sleigh(body)

func _affect_sleigh(sleigh):
	emit_signal("hit_by_sleigh")
	if sleigh.has_method("hit_obstacle"):
		sleigh.hit_obstacle()
	if sleigh.has_method("take_damage"):
		sleigh.take_damage(1)

func on_hit():
	GameManager.add_score(25)
	_destroy_effect()
	queue_free()

func _destroy_effect():
	var parent = get_parent()
	if not parent:
		return
	
	for i in range(8):
		var mandarin = ColorRect.new()
		mandarin.size = Vector2(15, 15)
		mandarin.color = Color(1, 0.6, 0.1)
		mandarin.global_position = global_position
		parent.add_child(mandarin)
		
		var tween = mandarin.create_tween()
		var target = global_position + Vector2(randf_range(-60, 60), randf_range(-80, -20))
		tween.set_parallel(true)
		tween.tween_property(mandarin, "global_position", target, 0.5)
		tween.tween_property(mandarin, "rotation", randf_range(-3, 3), 0.5)
		tween.tween_property(mandarin, "modulate:a", 0.0, 0.5)
		tween.set_parallel(false)
		tween.tween_callback(mandarin.queue_free)
