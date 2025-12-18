extends RigidBody2D

## Подарок - комбо при попадании, сброс при промахе/оливье
## Бонусы теперь собирает только ёлка!

signal hit_chimney(chimney: Node2D)
signal hit_blocker(blocker: Node2D)
signal missed

var initial_velocity: Vector2 = Vector2(350, 250)
var has_hit: bool = false
var is_star_gift: bool = false
var can_collect_bonuses: bool = false  # Подарки НЕ собирают бонусы - только ёлка!

var _collected_pickups: Array = []

func _ready():
	add_to_group("gift")
	gravity_scale = 0.8
	linear_velocity = initial_velocity
	
	body_entered.connect(_on_body_entered)
	
	var timer = get_tree().create_timer(5.0)
	timer.timeout.connect(_on_timeout)

func set_velocity(vel: Vector2):
	initial_velocity = vel
	linear_velocity = vel

func _physics_process(_delta):
	if linear_velocity.length() > 10:
		rotation = linear_velocity.angle()
	
	# Промах - улетел за экран
	if global_position.y > 800 or global_position.x > 1500 or global_position.x < -100:
		if not is_star_gift:
			GameManager.on_gift_missed()  # Сброс комбо
		emit_signal("missed")
		queue_free()
	
	# Проверяем препятствия
	_check_obstacles()

func _check_obstacles():
	if has_hit:
		return
	
	# Препятствия (оливье) - сбрасывают комбо
	var obstacles = get_tree().get_nodes_in_group("obstacle")
	for obs in obstacles:
		if not is_instance_valid(obs):
			continue
		if obs in _collected_pickups:
			continue
		
		if obs is Area2D:
			var dist = global_position.distance_to(obs.global_position)
			if dist < 50:
				_collected_pickups.append(obs)
				if obs.has_method("on_gift_hit"):
					obs.on_gift_hit(self)
				if not is_star_gift:
					GameManager.on_gift_hit_obstacle()  # Сброс комбо
				has_hit = true
				queue_free()
				return

func _on_body_entered(body):
	if has_hit:
		return
	
	if body.is_in_group("blocker"):
		has_hit = true
		emit_signal("hit_blocker", body)
		if body.has_method("on_gift_hit"):
			body.on_gift_hit(is_star_gift)
		elif body.has_method("on_hit"):
			body.on_hit()
		create_hit_effect(Color.ORANGE)
		queue_free()
	elif body.is_in_group("roof"):
		linear_velocity.y = -abs(linear_velocity.y) * 0.5
		linear_velocity.x *= 0.8
	elif body.is_in_group("trampoline"):
		if body.has_method("bounce_gift"):
			body.bounce_gift(self)

func create_hit_effect(color: Color = Color.WHITE):
	var effect = ColorRect.new()
	effect.color = color
	effect.color.a = 0.8
	effect.size = Vector2(40, 40)
	effect.position = Vector2(-20, -20)
	
	var parent = get_parent()
	if parent:
		var effect_node = Node2D.new()
		effect_node.global_position = global_position
		effect_node.add_child(effect)
		parent.add_child(effect_node)
		
		var tween = effect_node.create_tween()
		tween.tween_property(effect, "modulate:a", 0.0, 0.3)
		tween.tween_property(effect, "scale", Vector2(2, 2), 0.3)
		tween.tween_callback(effect_node.queue_free)

func on_chimney_hit():
	if has_hit:
		return
	has_hit = true
	
	if is_star_gift:
		GameManager.add_score(15, global_position)
	else:
		GameManager.on_chimney_hit()  # Добавляет комбо
	
	create_hit_effect(Color.GREEN)
	queue_free()

func _on_timeout():
	if not has_hit:
		if not is_star_gift:
			GameManager.on_gift_missed()  # Сброс комбо
		emit_signal("missed")
	queue_free()
