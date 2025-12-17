extends Area2D

## Звезда - раскидывание подарков

signal collected

func _ready():
	add_to_group("pickup")
	body_entered.connect(_on_body_entered)
	
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(self, "rotation_degrees", 360, 2.0)
	
	var pulse = create_tween()
	pulse.set_loops()
	pulse.tween_property(self, "scale", Vector2(1.2, 1.2), 0.3)
	pulse.tween_property(self, "scale", Vector2(1.0, 1.0), 0.3)

func _on_body_entered(body):
	if body.is_in_group("sleigh"):
		_collect()

func _collect():
	GameManager.activate_star_power(global_position)
	emit_signal("collected")
	
	_create_star_effect()
	_animate_collect()

func collect_by_gift():
	_collect()

func collect_by_tree():
	_collect()

func _animate_collect():
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(2.0, 2.0), 0.15)
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.tween_callback(queue_free)

func _create_star_effect():
	var parent = get_parent()
	if not parent:
		return
	
	for i in range(16):
		var ray = ColorRect.new()
		ray.size = Vector2(40, 8)
		ray.color = Color.GOLD
		ray.global_position = global_position
		ray.rotation = i * TAU / 16
		parent.add_child(ray)
		
		var angle = i * TAU / 16
		var target = global_position + Vector2(cos(angle), sin(angle)) * 120
		
		var tween = ray.create_tween()
		tween.set_parallel(true)
		tween.tween_property(ray, "global_position", target, 0.6)
		tween.tween_property(ray, "modulate:a", 0.0, 0.6)
		tween.set_parallel(false)
		tween.tween_callback(ray.queue_free)
