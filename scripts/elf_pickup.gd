extends Area2D

## Эльф - даёт 12-22 подарков

signal collected

func _ready():
	add_to_group("pickup")
	body_entered.connect(_on_body_entered)
	
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(self, "position:y", position.y - 12, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", position.y, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func _on_body_entered(body):
	if body.is_in_group("sleigh"):
		_collect()

func _collect():
	var bonus_gifts = randi_range(12, 22)  # Было 10-20
	GameManager.add_gifts(bonus_gifts, global_position)
	emit_signal("collected")
	SoundManager.play_sound("pickup")
	
	_create_gift_effect(bonus_gifts)
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

func _create_gift_effect(count: int):
	var parent = get_parent()
	if not parent:
		return
	
	for i in range(min(count, 12)):
		var gift = ColorRect.new()
		gift.size = Vector2(18, 18)
		gift.color = [Color.RED, Color.GREEN, Color.BLUE, Color.GOLD].pick_random()
		gift.global_position = global_position
		parent.add_child(gift)
		
		var angle = randf() * TAU
		var target = global_position + Vector2(cos(angle), sin(angle)) * randf_range(50, 100) + Vector2(0, -60)
		
		var tween = gift.create_tween()
		tween.set_parallel(true)
		tween.tween_property(gift, "global_position", target, 0.6)
		tween.tween_property(gift, "rotation", randf_range(-3, 3), 0.6)
		tween.tween_property(gift, "modulate:a", 0.0, 0.6)
		tween.set_parallel(false)
		tween.tween_callback(gift.queue_free)
