extends CharacterBody2D

## Сани - с сенсорным управлением

signal gift_thrown(gift: Node2D)

@export var move_speed: float = 350.0

var min_x: float = 80.0
var max_x: float = 450.0
var min_y: float = 50.0
var max_y: float = 550.0

var throw_cooldown: float = 0.0
var throw_rate: float = 0.35

var star_throw_timer: float = 0.0
var star_throw_rate: float = 0.35

var snowflakes: Array = []
var champagne_bottles_visual: Array = []
var foam_timer: float = 0.0

var _champagne_pressed: bool = false
var _tree_pressed: bool = false

# Сенсорное управление - свайпы
var swipe_direction: Vector2 = Vector2.ZERO
var touch_start_pos: Vector2 = Vector2.ZERO
var is_swiping: bool = false
const SWIPE_THRESHOLD: float = 10.0  # Минимальное расстояние для свайпа
const SWIPE_SENSITIVITY: float = 0.08  # Чувствительность свайпа

@onready var sprite: Node2D = $Sprite2D

func _ready():
	add_to_group("sleigh")
	position = Vector2(200, 200)
	
	GameManager.invincibility_started.connect(_on_invincibility_started)
	GameManager.invincibility_ended.connect(_on_invincibility_ended)
	GameManager.speed_boost_started.connect(_on_speed_boost_started)
	GameManager.speed_boost_ended.connect(_on_speed_boost_ended)
	GameManager.star_power_started.connect(_on_star_power_started)
	GameManager.star_power_ended.connect(_on_star_power_ended)

func _input(event):
	if not GameManager.is_game_running:
		return
	
	# Сенсорное управление - свайпы
	if event is InputEventScreenTouch:
		if event.pressed:
			# Начало касания
			touch_start_pos = event.position
			is_swiping = true
			swipe_direction = Vector2.ZERO
		else:
			# Конец касания - плавно останавливаемся
			is_swiping = false
	
	elif event is InputEventScreenDrag:
		if is_swiping:
			# Вычисляем направление свайпа относительно начальной точки
			var diff = event.position - touch_start_pos
			if diff.length() > SWIPE_THRESHOLD:
				swipe_direction = diff * SWIPE_SENSITIVITY
				# Ограничиваем максимальную скорость
				if swipe_direction.length() > 1.0:
					swipe_direction = swipe_direction.normalized()

func _physics_process(delta):
	if not GameManager.is_game_running:
		return
	
	_update_visual_effects(delta)
	
	var input_dir = Vector2.ZERO
	
	# Клавиатура
	if Input.is_action_pressed("move_up"):
		input_dir.y -= 1
	if Input.is_action_pressed("move_down"):
		input_dir.y += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1
	
	# Геймпад
	var joy_x = Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
	var joy_y = Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
	if abs(joy_x) > 0.2:
		input_dir.x += joy_x
	if abs(joy_y) > 0.2:
		input_dir.y += joy_y
	
	# Сенсорное управление - свайпы
	if is_swiping and swipe_direction.length() > 0.1:
		input_dir += swipe_direction
	elif not is_swiping:
		# Плавное затухание при отпускании
		swipe_direction = swipe_direction.lerp(Vector2.ZERO, 0.2)
	
	input_dir = input_dir.normalized()
	velocity = input_dir * move_speed
	
	var collision = move_and_collide(velocity * delta)
	
	if collision:
		var collider = collision.get_collider()
		if collider and collider.is_in_group("roof"):
			hit_roof(collision.get_normal())
	
	position.x = clamp(position.x, min_x, max_x)
	position.y = clamp(position.y, min_y, max_y)
	
	# Бросок подарков - клавиатура/мышь
	throw_cooldown -= delta
	if throw_cooldown <= 0:
		var can_throw = false
		
		# Геймпад
		if Input.is_joy_button_pressed(0, JOY_BUTTON_A):
			can_throw = true
		
		# Мышь/клавиатура - только если не над UI
		if Input.is_action_pressed("throw_gift"):
			if not _is_mouse_over_ui():
				can_throw = true
		
		if can_throw and GameManager.gifts > 0:
			throw_gift()
	
	# Звёздная сила
	if GameManager.is_star_power_active():
		star_throw_timer -= delta
		if star_throw_timer <= 0:
			throw_star_gifts()
			star_throw_timer = star_throw_rate
	
	# Ускорение
	var champagne_btn = Input.is_joy_button_pressed(0, JOY_BUTTON_RIGHT_SHOULDER)
	if Input.is_action_just_pressed("use_champagne") or (champagne_btn and not _champagne_pressed):
		if GameManager.use_champagne():
			SoundManager.play_sound("boost")
	_champagne_pressed = champagne_btn
	
	# Ёлка
	var tree_btn = Input.is_joy_button_pressed(0, JOY_BUTTON_LEFT_SHOULDER)
	if Input.is_action_just_pressed("use_tree") or (tree_btn and not _tree_pressed):
		use_tree_grenade()
	_tree_pressed = tree_btn

func _is_mouse_over_ui() -> bool:
	var mouse_pos = get_viewport().get_mouse_position()
	if mouse_pos.y < 100:
		return true
	return false

func _update_visual_effects(delta):
	if GameManager.is_damage_invincible() and not GameManager.is_invincible() and not GameManager.is_animation_invincible():
		if sprite:
			sprite.modulate.a = 0.5 if fmod(Time.get_ticks_msec(), 200) < 100 else 1.0
	elif not GameManager.is_invincible() and not GameManager.is_speed_boosted() and not GameManager.is_star_power_active():
		if sprite:
			sprite.modulate = Color.WHITE
	
	if GameManager.is_speed_boosted():
		if sprite:
			sprite.modulate = Color(1.2, 1.1, 0.8)
		_update_champagne_foam(delta)
	
	if GameManager.is_star_power_active():
		if sprite:
			sprite.modulate = Color(1.4, 1.3, 0.6)
	
	_update_snowflakes()

func _update_snowflakes():
	if not GameManager.is_invincible():
		return
	
	var time = Time.get_ticks_msec() / 1000.0
	for i in range(snowflakes.size()):
		var flake = snowflakes[i]
		if is_instance_valid(flake):
			var angle = time * 2.5 + i * TAU / snowflakes.size()
			var radius = 65 + sin(time * 3 + i) * 5
			flake.position = Vector2(cos(angle), sin(angle)) * radius
			flake.rotation = time * 2

func _update_champagne_foam(delta):
	foam_timer += delta
	if foam_timer >= 0.08:
		foam_timer = 0.0
		_emit_foam()

func _emit_foam():
	var parent = get_parent()
	if not parent:
		return
	
	for bottle in champagne_bottles_visual:
		if is_instance_valid(bottle):
			var foam = ColorRect.new()
			foam.size = Vector2(randf_range(6, 12), randf_range(6, 12))
			foam.color = Color(1, 0.95, 0.8, 0.8)
			foam.global_position = global_position + Vector2(-50 + randf_range(-10, 10), randf_range(-10, 20))
			parent.add_child(foam)
			
			var tween = foam.create_tween()
			tween.set_parallel(true)
			tween.tween_property(foam, "global_position:x", foam.global_position.x - randf_range(40, 80), 0.4)
			tween.tween_property(foam, "modulate:a", 0.0, 0.4)
			tween.set_parallel(false)
			tween.tween_callback(foam.queue_free)

func throw_gift():
	if throw_cooldown > 0:
		return
	if not GameManager.use_gift():
		return
	
	throw_cooldown = throw_rate
	
	var gift_scene = preload("res://scenes/gift.tscn")
	var gift = gift_scene.instantiate()
	gift.global_position = global_position + Vector2(50, 20)
	gift.set_velocity(Vector2(400, 280))
	
	get_parent().add_child(gift)
	emit_signal("gift_thrown", gift)
	SoundManager.play_sound("throw")

func throw_star_gifts():
	var gift_scene = preload("res://scenes/gift.tscn")
	var count = randi_range(4, 6)
	
	var star_colors = [
		Color(0.2, 0.6, 1.0),    # Синий
		Color(0.2, 1.0, 0.4),    # Зелёный
		Color(1.0, 1.0, 0.2),    # Жёлтый
		Color(1.0, 0.4, 0.8),    # Розовый
		Color(0.6, 0.4, 1.0),    # Фиолетовый
		Color(0.2, 1.0, 1.0),    # Бирюзовый
	]
	
	for i in range(count):
		var gift = gift_scene.instantiate()
		gift.global_position = global_position
		gift.is_star_gift = true
		gift.can_collect_bonuses = false
		
		var angle = i * TAU / count + randf() * 0.3
		var speed = randf_range(300, 450)
		gift.set_velocity(Vector2(cos(angle), sin(angle)) * speed)
		gift.modulate = star_colors[i % star_colors.size()]
		
		get_parent().add_child(gift)
	
	SoundManager.play_sound("star_throw")

func use_tree_grenade():
	if GameManager.use_tree_charge():
		var tree_scene = preload("res://scenes/tree_grenade.tscn")
		var tree = tree_scene.instantiate()
		tree.global_position = global_position + Vector2(60, 40)
		get_parent().add_child(tree)
		SoundManager.play_sound("tree_launch")

func take_damage(amount: int = 1):
	if GameManager.take_damage(amount):
		return
	
	SoundManager.play_sound("damage")
	
	if sprite and not GameManager.is_invincible() and not GameManager.is_animation_invincible():
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color.RED, 0.1)
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)

func hit_obstacle():
	if GameManager.is_any_invincible():
		return
	
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "position", Vector2(5, 0), 0.05)
		tween.tween_property(sprite, "position", Vector2(-5, 0), 0.05)
		tween.tween_property(sprite, "position", Vector2(0, 0), 0.05)

func hit_roof(normal: Vector2):
	position += normal * 20
	take_damage(1)
	hit_obstacle()

func _on_invincibility_started():
	_create_snowflakes()
	SoundManager.play_sound("shield")

func _on_invincibility_ended():
	_remove_snowflakes()

func _on_speed_boost_started():
	_create_champagne_bottles()

func _on_speed_boost_ended():
	_remove_champagne_bottles()
	if sprite and not GameManager.is_star_power_active():
		sprite.modulate = Color.WHITE

func _on_star_power_started():
	star_throw_timer = 0
	SoundManager.play_sound("star_power")

func _on_star_power_ended():
	if sprite and not GameManager.is_speed_boosted():
		sprite.modulate = Color.WHITE

func _create_snowflakes():
	_remove_snowflakes()
	
	for i in range(6):
		var flake = Label.new()
		flake.text = "❄"
		flake.add_theme_font_size_override("font_size", 16)
		flake.add_theme_color_override("font_color", Color(0.8, 0.9, 1, 0.8))
		flake.z_index = 10
		add_child(flake)
		snowflakes.append(flake)

func _remove_snowflakes():
	for flake in snowflakes:
		if is_instance_valid(flake):
			flake.queue_free()
	snowflakes.clear()

func _create_champagne_bottles():
	_remove_champagne_bottles()
	
	for i in range(2):
		var bottle = Node2D.new()
		bottle.position = Vector2(-45, -5 + i * 20)
		bottle.z_index = -1
		
		var body = ColorRect.new()
		body.size = Vector2(25, 12)
		body.position = Vector2(0, -6)
		body.color = Color(0.12, 0.35, 0.15)
		bottle.add_child(body)
		
		var neck = ColorRect.new()
		neck.size = Vector2(15, 6)
		neck.position = Vector2(-15, -3)
		neck.color = Color(0.12, 0.35, 0.15)
		bottle.add_child(neck)
		
		var foil = ColorRect.new()
		foil.size = Vector2(8, 8)
		foil.position = Vector2(-23, -4)
		foil.color = Color(0.95, 0.8, 0.2)
		bottle.add_child(foil)
		
		add_child(bottle)
		champagne_bottles_visual.append(bottle)

func _remove_champagne_bottles():
	for bottle in champagne_bottles_visual:
		if is_instance_valid(bottle):
			bottle.queue_free()
	champagne_bottles_visual.clear()
