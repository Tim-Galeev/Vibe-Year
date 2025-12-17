extends Area2D

## Пряничный человечек - неуязвимость

signal collected

func _ready():
	add_to_group("pickup")
	body_entered.connect(_on_body_entered)
	
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(self, "rotation_degrees", 10, 0.4).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "rotation_degrees", -10, 0.4).set_trans(Tween.TRANS_SINE)

func _on_body_entered(body):
	if body.is_in_group("sleigh"):
		_collect()

func _collect():
	GameManager.activate_invincibility(global_position)
	emit_signal("collected")
	
	_create_sparkle_effect()
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

func _create_sparkle_effect():
	var parent = get_parent()
	if not parent:
		return
	
	for i in range(10):
		var sparkle = ColorRect.new()
		sparkle.size = Vector2(10, 10)
		sparkle.color = [Color.GOLD, Color.WHITE, Color(1, 0.8, 0.5)].pick_random()
		sparkle.global_position = global_position
		parent.add_child(sparkle)
		
		var angle = i * TAU / 10
		var target = global_position + Vector2(cos(angle), sin(angle)) * 60
		
		var tween = sparkle.create_tween()
		tween.set_parallel(true)
		tween.tween_property(sparkle, "global_position", target, 0.5)
		tween.tween_property(sparkle, "modulate:a", 0.0, 0.5)
		tween.set_parallel(false)
		tween.tween_callback(sparkle.queue_free)
