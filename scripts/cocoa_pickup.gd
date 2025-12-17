extends Area2D

## Какао - восстанавливает здоровье

signal collected

func _ready():
	add_to_group("pickup")
	body_entered.connect(_on_body_entered)
	
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(self, "position:y", position.y - 8, 0.6).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "position:y", position.y + 8, 0.6).set_trans(Tween.TRANS_SINE)

func _on_body_entered(body):
	if body.is_in_group("sleigh"):
		_collect()

func _collect():
	GameManager.heal(1, global_position)
	emit_signal("collected")
	SoundManager.play_sound("pickup")
	
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
