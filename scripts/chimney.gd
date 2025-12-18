extends Area2D

## Дымоход - цель для подарков, комбо-система

signal gift_received

var has_blocker: bool = false
var blocker_node: Node2D = null

func _ready():
	add_to_group("chimney")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if not body.is_in_group("gift"):
		return
	
	if has_blocker and is_instance_valid(blocker_node):
		return
	
	var is_star = body.get("is_star_gift") if body.get("is_star_gift") != null else false
	
	emit_signal("gift_received")
	
	if is_star:
		GameManager.add_score(15, global_position)
		SoundManager.play_sound("chimney_hit")
	else:
		# Обычный подарок - очки с учётом комбо
		GameManager.add_score(100, global_position)
		GameManager.on_chimney_hit()  # Увеличивает комбо
		
		# Звук с pitch в зависимости от комбо (меняется каждые 3 попадания)
		var combo = GameManager.get_combo_count()
		var pitch_level = combo / 3  # Каждые 3 попадания = +1 уровень
		var pitch = 1.0 + pitch_level * 0.1  # +10% за каждые 3
		pitch = min(pitch, 2.0)  # Максимум x2
		SoundManager.play_sound_pitched("chimney_hit", pitch)
	
	if body.has_method("on_chimney_hit"):
		body.on_chimney_hit()
	
	create_success_effect()

func add_blocker():
	if has_blocker:
		return
	
	has_blocker = true
	var blocker_scene = preload("res://scenes/ornament_blocker.tscn")
	blocker_node = blocker_scene.instantiate()
	blocker_node.position = Vector2(0, -50)
	add_child(blocker_node)
	
	if blocker_node.has_signal("destroyed"):
		blocker_node.destroyed.connect(_on_blocker_destroyed)

func _on_blocker_destroyed():
	has_blocker = false
	blocker_node = null

func create_success_effect():
	var chimney_visual = $ChimneyVisual
	if chimney_visual:
		var original_modulate = chimney_visual.modulate
		var tween = create_tween()
		tween.tween_property(chimney_visual, "modulate", Color.GREEN, 0.1)
		tween.tween_property(chimney_visual, "modulate", original_modulate, 0.3)
	
	# Больше частиц при высоком комбо
	var combo = GameManager.get_combo_count()
	var particle_count = 10 + min(combo, 10)
	
	for i in range(particle_count):
		var particle = ColorRect.new()
		particle.size = Vector2(randf_range(6, 12), randf_range(6, 12))
		particle.position = Vector2(randf_range(-20, 20), -70)
		
		# Цвет зависит от комбо
		if combo >= 10:
			particle.color = [Color.GOLD, Color.ORANGE, Color.RED].pick_random()
		elif combo >= 5:
			particle.color = [Color.GOLD, Color.YELLOW, Color.WHITE].pick_random()
		else:
			particle.color = [Color.RED, Color.GREEN, Color.GOLD, Color.WHITE].pick_random()
		
		add_child(particle)
		
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(particle, "position:y", -150 + randf_range(-30, 30), 0.6)
		tween.tween_property(particle, "position:x", particle.position.x + randf_range(-60, 60), 0.6)
		tween.tween_property(particle, "modulate:a", 0.0, 0.6)
		tween.set_parallel(false)
		tween.tween_callback(particle.queue_free)
