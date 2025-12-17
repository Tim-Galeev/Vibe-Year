extends RigidBody2D

## Подарок - ФИКС: звёздные не собирают бонусы, проверка на дубли

signal hit_chimney(chimney: Node2D)
signal hit_blocker(blocker: Node2D)
signal missed

var initial_velocity: Vector2 = Vector2(350, 250)
var has_hit: bool = false
var is_star_gift: bool = false
var can_collect_bonuses: bool = true  # Звёздные подарки не собирают

var _collected_pickups: Array = []  # Предотвращаем дублирование

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
	
	if global_position.y > 800 or global_position.x > 1500 or global_position.x < -100:
		emit_signal("missed")
		queue_free()
	
	# Проверяем пересечения только если можем собирать
	if can_collect_bonuses:
		_check_area_overlaps()

func _check_area_overlaps():
	if has_hit:
		return
	
	# Бонусы - только если не звёздный подарок
	var pickups = get_tree().get_nodes_in_group("pickup")
	for pickup in pickups:
		if not is_instance_valid(pickup):
			continue
		if pickup in _collected_pickups:
			continue  # Уже собрали этот
		
		if pickup is Area2D:
			var dist = global_position.distance_to(pickup.global_position)
			if dist < 40:
				_collected_pickups.append(pickup)
				if pickup.has_method("collect_by_gift"):
					pickup.collect_by_gift()
	
	# Препятствия (оливье)
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
	
	# Звёздные дают меньше очков
	if is_star_gift:
		GameManager.add_score(15, global_position)  # Было 50
	else:
		# Обычные попадания сбрасывают таймер decay
		GameManager.on_chimney_hit()
	
	create_hit_effect(Color.GREEN)
	queue_free()

func _on_timeout():
	if not has_hit:
		emit_signal("missed")
	queue_free()
