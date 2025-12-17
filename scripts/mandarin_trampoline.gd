extends Area2D

## Батут из мандаринов - отбивает подарки вверх (помогает попасть в трубу)

func _ready():
	add_to_group("trampoline")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("gift"):
		_bounce_gift(body)

func _bounce_gift(gift):
	# Отбиваем подарок вверх и немного вперёд
	if gift.has_method("set_velocity"):
		gift.set_velocity(Vector2(200, -400))
	else:
		gift.linear_velocity = Vector2(200, -400)
	
	SoundManager.play_sound("bounce")
	
	# Анимация сжатия и отскока
	var tween = create_tween()
	tween.tween_property($Visual, "scale", Vector2(1.3, 0.6), 0.06)
	tween.tween_property($Visual, "scale", Vector2(0.9, 1.2), 0.08)
	tween.tween_property($Visual, "scale", Vector2(1.0, 1.0), 0.08)

func on_hit():
	# Уничтожение от ёлки
	GameManager.add_score(25)
	_destroy_effect()
	queue_free()

func _destroy_effect():
	var parent = get_parent()
	if not parent:
		return
	
	for i in range(10):
		var mandarin = ColorRect.new()
		mandarin.size = Vector2(18, 18)
		mandarin.color = Color(1, 0.6, 0.1)
		mandarin.global_position = global_position + Vector2(randf_range(-20, 20), randf_range(-10, 10))
		parent.add_child(mandarin)
		
		var tween = mandarin.create_tween()
		var target = mandarin.global_position + Vector2(randf_range(-80, 80), randf_range(-120, -40))
		tween.set_parallel(true)
		tween.tween_property(mandarin, "global_position", target, 0.6)
		tween.tween_property(mandarin, "rotation", randf_range(-5, 5), 0.6)
		tween.tween_property(mandarin, "modulate:a", 0.0, 0.6)
		tween.set_parallel(false)
		tween.tween_callback(mandarin.queue_free)
