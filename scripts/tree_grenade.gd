extends RigidBody2D

## Ёлка - ТОЛЬКО она собирает бонусы, уничтожает салюты, больше радиус

signal exploded

@export var launch_velocity: Vector2 = Vector2(350, 150)
@export var effect_radius: float = 350.0  # Было 280, увеличено

var has_exploded: bool = false
var is_activating: bool = false
var activation_time: float = 0.0
var activation_duration: float = 0.8

var _collected_objects: Array = []

func _ready():
	add_to_group("tree_grenade")
	gravity_scale = 0.5
	linear_velocity = launch_velocity
	
	contact_monitor = true
	max_contacts_reported = 8
	body_entered.connect(_on_body_entered)
	
	rotation = 0
	angular_velocity = 0
	lock_rotation = true

func _physics_process(delta):
	if has_exploded:
		return
	
	rotation = 0
	
	if is_activating:
		activation_time += delta
		_emit_needles()
		
		if activation_time >= activation_duration:
			_finish_activation()
		return
	
	# Собираем бонусы, уничтожаем препятствия и салюты
	_collect_in_radius()
	
	if global_position.x > 1600 or global_position.y > 800 or global_position.x < -200:
		queue_free()

func _on_body_entered(body):
	if has_exploded or is_activating:
		return
	
	if body.is_in_group("roof"):
		_start_activation()

func _start_activation():
	if is_activating:
		return
	
	is_activating = true
	activation_time = 0.0
	linear_velocity = Vector2.ZERO
	gravity_scale = 0
	
	SoundManager.play_sound("tree_launch")
	emit_signal("exploded")

func _collect_in_radius():
	# Бонусы - ТОЛЬКО ёлка собирает их
	var pickups = get_tree().get_nodes_in_group("pickup")
	for pickup in pickups:
		if not is_instance_valid(pickup):
			continue
		if pickup in _collected_objects:
			continue
		
		var dist = global_position.distance_to(pickup.global_position)
		if dist < effect_radius:
			_collected_objects.append(pickup)
			if pickup.has_method("collect_by_tree"):
				pickup.collect_by_tree()
	
	# Препятствия (оливье)
	var obstacles = get_tree().get_nodes_in_group("obstacle")
	for obs in obstacles:
		if not is_instance_valid(obs):
			continue
		if obs in _collected_objects:
			continue
		
		var dist = global_position.distance_to(obs.global_position)
		if dist < effect_radius * 0.8:
			_collected_objects.append(obs)
			if obs.has_method("on_hit"):
				obs.on_hit()
	
	# Блокеры (шарики)
	var blockers = get_tree().get_nodes_in_group("blocker")
	for blocker in blockers:
		if not is_instance_valid(blocker):
			continue
		if blocker in _collected_objects:
			continue
		
		var dist = global_position.distance_to(blocker.global_position)
		if dist < effect_radius * 0.8:
			_collected_objects.append(blocker)
			if blocker.has_method("on_hit"):
				blocker.on_hit()
	
	# Салюты - ёлка сгорает вместе с ними!
	var hazards = get_tree().get_nodes_in_group("hazard")
	for hazard in hazards:
		if not is_instance_valid(hazard):
			continue
		if hazard in _collected_objects:
			continue
		
		var dist = global_position.distance_to(hazard.global_position)
		if dist < effect_radius * 0.6:
			_collected_objects.append(hazard)
			# Ёлка сгорает в салюте!
			_create_burn_effect(hazard.global_position)
			hazard.queue_free()
			has_exploded = true
			queue_free()
			return

func _create_burn_effect(firework_pos: Vector2):
	var parent = get_parent()
	if not parent:
		return
	
	var burn_pos = global_position
	
	# Огонь и искры - ёлка сгорает!
	for i in range(40):
		var spark = ColorRect.new()
		var spark_size = randf_range(6, 18)
		spark.size = Vector2(spark_size, spark_size)
		
		# Огненные цвета
		var fire_colors = [
			Color(1, 0.3, 0),      # Оранжевый
			Color(1, 0.5, 0),      # Светло-оранжевый
			Color(1, 0.8, 0),      # Жёлтый
			Color(1, 0.1, 0),      # Красный
			Color(1, 1, 0.3),      # Светло-жёлтый
		]
		spark.color = fire_colors.pick_random()
		spark.global_position = burn_pos + Vector2(randf_range(-20, 20), randf_range(-30, 10))
		parent.add_child(spark)
		
		# Огонь поднимается вверх
		var angle = randf_range(-PI * 0.8, -PI * 0.2)  # Вверх с разбросом
		var speed = randf_range(80, 200)
		var target = spark.global_position + Vector2(cos(angle), sin(angle)) * speed
		
		var duration = randf_range(0.4, 0.9)
		var tween = spark.create_tween()
		tween.set_parallel(true)
		tween.tween_property(spark, "global_position", target, duration)
		tween.tween_property(spark, "scale", Vector2(0.2, 0.2), duration)
		tween.tween_property(spark, "modulate:a", 0.0, duration)
		tween.set_parallel(false)
		tween.tween_callback(spark.queue_free)
	
	# Дым
	for i in range(10):
		var smoke = ColorRect.new()
		var smoke_size = randf_range(15, 30)
		smoke.size = Vector2(smoke_size, smoke_size)
		smoke.color = Color(0.3, 0.3, 0.3, 0.6)
		smoke.global_position = burn_pos + Vector2(randf_range(-15, 15), randf_range(-20, 0))
		parent.add_child(smoke)
		
		var target = smoke.global_position + Vector2(randf_range(-30, 30), randf_range(-100, -60))
		
		var tween = smoke.create_tween()
		tween.set_parallel(true)
		tween.tween_property(smoke, "global_position", target, 1.2)
		tween.tween_property(smoke, "scale", Vector2(2, 2), 1.2)
		tween.tween_property(smoke, "modulate:a", 0.0, 1.2)
		tween.set_parallel(false)
		tween.tween_callback(smoke.queue_free)
	
	# Взрыв салюта тоже
	for i in range(15):
		var fw_spark = ColorRect.new()
		fw_spark.size = Vector2(randf_range(5, 10), randf_range(5, 10))
		fw_spark.color = [Color.RED, Color.BLUE, Color.YELLOW, Color.MAGENTA].pick_random()
		fw_spark.global_position = firework_pos
		parent.add_child(fw_spark)
		
		var angle = randf() * TAU
		var speed = randf_range(100, 180)
		var target = fw_spark.global_position + Vector2(cos(angle), sin(angle)) * speed
		
		var tween = fw_spark.create_tween()
		tween.set_parallel(true)
		tween.tween_property(fw_spark, "global_position", target, 0.6)
		tween.tween_property(fw_spark, "modulate:a", 0.0, 0.6)
		tween.set_parallel(false)
		tween.tween_callback(fw_spark.queue_free)
	
	SoundManager.play_sound("explosion")

func _emit_needles():
	var parent = get_parent()
	if not parent:
		return
	
	for i in range(3):
		var needle = ColorRect.new()
		needle.size = Vector2(randf_range(10, 20), 3)
		needle.color = Color(0.15 + randf() * 0.1, 0.5 + randf() * 0.15, 0.2 + randf() * 0.1)
		needle.global_position = global_position + Vector2(randf_range(-25, 25), randf_range(-30, 30))
		needle.rotation = randf() * TAU
		parent.add_child(needle)
		
		var angle = randf() * TAU
		var speed = randf_range(120, 280)
		var target = needle.global_position + Vector2(cos(angle), sin(angle)) * speed
		
		var tween = needle.create_tween()
		tween.set_parallel(true)
		tween.tween_property(needle, "global_position", target, 0.7)
		tween.tween_property(needle, "modulate:a", 0.0, 0.7)
		tween.set_parallel(false)
		tween.tween_callback(needle.queue_free)
	
	if randf() < 0.4:
		var ornament = ColorRect.new()
		ornament.size = Vector2(12, 12)
		ornament.color = [Color.RED, Color.BLUE, Color.GOLD, Color.MAGENTA].pick_random()
		ornament.global_position = global_position + Vector2(randf_range(-20, 20), randf_range(-25, 25))
		parent.add_child(ornament)
		
		var angle = randf() * TAU
		var target = ornament.global_position + Vector2(cos(angle), sin(angle)) * randf_range(100, 180)
		
		var tween = ornament.create_tween()
		tween.set_parallel(true)
		tween.tween_property(ornament, "global_position", target, 0.6)
		tween.tween_property(ornament, "rotation", randf_range(-5, 5), 0.6)
		tween.tween_property(ornament, "modulate:a", 0.0, 0.6)
		tween.set_parallel(false)
		tween.tween_callback(ornament.queue_free)
	
	_update_tree_visual()

func _update_tree_visual():
	var progress = activation_time / activation_duration
	var visual = $Visual
	if visual:
		for child in visual.get_children():
			if "Layer" in child.name or "Top" in child.name:
				child.modulate.a = 1.0 - progress * 0.9

func _finish_activation():
	has_exploded = true
	_collect_in_radius()
	_create_final_burst()
	queue_free()

func _create_final_burst():
	var parent = get_parent()
	if not parent:
		return
	
	for i in range(20):
		var confetti = ColorRect.new()
		confetti.size = Vector2(randf_range(8, 15), randf_range(8, 15))
		confetti.color = [Color.RED, Color.GREEN, Color.GOLD, Color.WHITE, Color.CYAN].pick_random()
		confetti.global_position = global_position
		parent.add_child(confetti)
		
		var angle = randf() * TAU
		var target = global_position + Vector2(cos(angle), sin(angle)) * randf_range(80, 200)
		
		var tween = confetti.create_tween()
		tween.set_parallel(true)
		tween.tween_property(confetti, "global_position", target, 0.8)
		tween.tween_property(confetti, "rotation", randf_range(-6, 6), 0.8)
		tween.tween_property(confetti, "modulate:a", 0.0, 0.8)
		tween.set_parallel(false)
		tween.tween_callback(confetti.queue_free)
