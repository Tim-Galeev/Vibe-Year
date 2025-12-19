extends Node2D

## Генератор уровня - частота бонусов зависит от активности игрока

signal roof_passed(roof: Node2D)

@export var spawn_distance: float = 1400.0
@export var despawn_distance: float = -400.0
@export var min_gap: float = 25.0
@export var max_gap: float = 70.0

var roofs: Array = []
var next_spawn_x: float = 300.0

var base_roof_y: float = 520.0
var min_roof_y: float = 350.0
var max_roof_y: float = 580.0

var roof_scene: PackedScene
var firework_scene: PackedScene

var houses_spawned: int = 0
var hard_segment_houses: int = 0
var _initialized: bool = false

func _ready():
	roof_scene = preload("res://scenes/roof.tscn")
	firework_scene = preload("res://scenes/firework.tscn")
	GameManager.game_started.connect(_on_game_started)

func _on_game_started():
	_clear_all()
	_spawn_initial_roofs()
	_initialized = true

func _clear_all():
	for roof in roofs:
		if is_instance_valid(roof):
			roof.queue_free()
	roofs.clear()
	
	for child in get_children():
		if child.is_in_group("hazard"):
			child.queue_free()
	
	next_spawn_x = 300.0
	houses_spawned = 0
	hard_segment_houses = 0

func _spawn_initial_roofs():
	for i in range(8):
		spawn_roof()

func _process(delta):
	if not GameManager.is_game_running:
		return
	
	if not _initialized:
		return
	
	var scroll_speed = GameManager.get_current_scroll_speed()
	
	for roof in roofs:
		if is_instance_valid(roof):
			roof.position.x -= scroll_speed * delta
	
	for roof in roofs.duplicate():
		if is_instance_valid(roof) and roof.position.x < despawn_distance:
			emit_signal("roof_passed", roof)
			roofs.erase(roof)
			roof.queue_free()
	
	next_spawn_x -= scroll_speed * delta
	
	while next_spawn_x < spawn_distance:
		spawn_roof()
	
	_maybe_spawn_firework()

func _maybe_spawn_firework():
	if not GameManager.can_spawn_fireworks():
		return
	
	if randf() < 0.008:
		_spawn_firework()

func _spawn_firework():
	if not firework_scene:
		return
	
	GameManager.register_firework_spawn()
	
	var firework = firework_scene.instantiate()
	firework.global_position = Vector2(1350, randf_range(120, 320))
	add_child(firework)

func spawn_roof():
	if roof_scene == null:
		return
	
	var roof = roof_scene.instantiate()
	
	var difficulty = GameManager.game_speed
	var height_variance = 80 + difficulty * 40
	
	var roof_y: float
	if GameManager.is_in_hard_segment():
		if randf() < 0.5:
			roof_y = randf_range(min_roof_y, min_roof_y + 60)
		else:
			roof_y = randf_range(max_roof_y - 60, max_roof_y)
	else:
		roof_y = base_roof_y + randf_range(-height_variance, height_variance * 0.5)
		roof_y = clamp(roof_y, min_roof_y, max_roof_y)
	
	roof.position = Vector2(next_spawn_x, roof_y)
	add_child(roof)
	roofs.append(roof)
	
	houses_spawned += 1
	call_deferred("setup_roof", roof, roof_y)
	
	var roof_width = randi_range(140, 320)
	var gap = randf_range(min_gap, max_gap)
	
	if GameManager.is_in_hard_segment():
		gap *= 0.6
	
	next_spawn_x += roof_width + gap
	
	_check_hard_segment()

func _check_hard_segment():
	if GameManager.is_in_cooldown():
		return
	
	if not GameManager.intro_star_given:
		return
	
	if not GameManager.is_in_hard_segment() and randf() < 0.03:
		GameManager.start_hard_segment(3.0)
		hard_segment_houses = 0

func setup_roof(roof: Node2D, roof_y: float):
	if not is_instance_valid(roof):
		return
	
	var width = randi_range(140, 320)
	if roof.has_method("set_width"):
		roof.set_width(width)
	
	# Высота здания до низа экрана (адаптивно)
	var viewport_height = get_viewport_rect().size.y
	var building_height = viewport_height - roof_y + 100
	if roof.has_method("set_building_height"):
		roof.set_building_height(building_height)
	
	if randf() < 0.2 and roof.has_method("add_garland"):
		roof.add_garland()
	
	var chimney_x = randf_range(0.3, 0.7) * width
	if roof.has_method("add_chimney"):
		roof.add_chimney(chimney_x)
	
	var safe_zones = _get_safe_spawn_zones(width, chimney_x)
	
	_spawn_progressive_content(roof, width, safe_zones, roof_y)

func _spawn_progressive_content(roof: Node2D, width: float, safe_zones: Array, roof_y: float):
	if GameManager.should_spawn_intro_cocoa():
		if GameManager.can_spawn_bonus():
			_spawn_pickup_safe(roof, "cocoa", safe_zones, roof_y)
			GameManager.mark_intro_cocoa_given()
			return
	
	if GameManager.should_spawn_intro_obstacle():
		_spawn_obstacle_safe(roof, "olivie", safe_zones)
		GameManager.mark_intro_obstacle_added()
		return
	
	if GameManager.should_spawn_intro_elf():
		if GameManager.can_spawn_bonus():
			_spawn_pickup_safe(roof, "elf", safe_zones, roof_y)
			GameManager.mark_intro_elf_given()
			return
	
	if GameManager.should_spawn_first_star():
		if GameManager.can_spawn_bonus():
			_spawn_pickup_safe(roof, "star", safe_zones, roof_y)
			GameManager.mark_first_star_given()
			return
	
	if GameManager.intro_star_given:
		_spawn_regular_content(roof, width, safe_zones, roof_y)

func _spawn_regular_content(roof: Node2D, width: float, safe_zones: Array, roof_y: float):
	var difficulty = min(GameManager.game_speed, 2.5)
	var bonus_freq = GameManager.get_bonus_frequency()  # 0.1 - 1.0
	
	var obstacle_chance = 0.1 * difficulty
	if GameManager.is_in_hard_segment():
		obstacle_chance *= 2.0
	
	if randf() < obstacle_chance:
		_spawn_obstacle_safe(roof, "olivie", safe_zones)
	
	if randf() < 0.12 * difficulty:
		if roof.has_method("add_blocker"):
			roof.add_blocker()
	
	if randf() < 0.08:
		_spawn_helper_safe(roof, "mandarin_trampoline", safe_zones)
	
	# Бонусы - частота зависит от активности игрока
	if GameManager.can_spawn_bonus() and not GameManager.is_in_hard_segment():
		var bonus = _choose_bonus(bonus_freq)
		if bonus != "":
			_spawn_pickup_safe(roof, bonus, safe_zones, roof_y)
			GameManager.register_bonus_spawn(bonus)
	
	if GameManager.is_in_cooldown() and GameManager.lives_lost > 0:
		if GameManager.can_spawn_bonus() and randf() < 0.15:
			_spawn_pickup_safe(roof, "cocoa", safe_zones, roof_y)
			GameManager.register_bonus_spawn("cocoa")

func _choose_bonus(frequency: float) -> String:
	# Чем ниже frequency, тем меньше шанс бонуса
	if randf() > 0.4 * frequency:
		return ""
	
	var available = []
	
	if "elf" in GameManager.unlocked_bonuses and GameManager.gifts < 12:
		available.append("elf")
	
	if "cocoa" in GameManager.unlocked_bonuses and GameManager.lives_lost > 0 and GameManager.lives < 3:
		available.append("cocoa")
	
	if GameManager.intro_cocoa_given:
		if "champagne" not in GameManager.unlocked_bonuses:
			GameManager.unlock_bonus("champagne")
		if GameManager.champagne_bottles < 2:
			available.append("champagne")
	
	if GameManager.intro_obstacle_added:
		if "gingerbread" not in GameManager.unlocked_bonuses:
			GameManager.unlock_bonus("gingerbread")
		if GameManager.lives_lost > 0 and randf() < 0.3:
			available.append("gingerbread")
	
	if GameManager.intro_star_given and randf() < 0.08:
		available.append("star")
	
	if available.size() == 0:
		return ""
	
	return available.pick_random()

func _get_safe_spawn_zones(width: float, chimney_x: float) -> Array:
	var zones = []
	var chimney_margin = 70
	
	if chimney_x - chimney_margin > 50:
		zones.append({"min": 40, "max": chimney_x - chimney_margin})
	if chimney_x + chimney_margin < width - 50:
		zones.append({"min": chimney_x + chimney_margin, "max": width - 40})
	
	if zones.size() == 0:
		zones.append({"min": 40, "max": width - 40})
	
	return zones

func _get_random_x_from_zones(zones: Array) -> float:
	var zone = zones.pick_random()
	return randf_range(zone["min"], zone["max"])

func _spawn_obstacle_safe(roof: Node2D, obstacle_type: String, safe_zones: Array):
	var scene_path = ""
	match obstacle_type:
		"olivie":
			scene_path = "res://scenes/olivie.tscn"
	
	if scene_path == "":
		return
	
	var obstacle_scene = load(scene_path)
	if obstacle_scene:
		var obstacle = obstacle_scene.instantiate()
		obstacle.position = Vector2(_get_random_x_from_zones(safe_zones), -25)
		roof.add_child(obstacle)

func _spawn_helper_safe(roof: Node2D, helper_type: String, safe_zones: Array):
	var scene_path = ""
	match helper_type:
		"mandarin_trampoline":
			scene_path = "res://scenes/mandarin_trampoline.tscn"
	
	if scene_path == "":
		return
	
	var helper_scene = load(scene_path)
	if helper_scene:
		var helper = helper_scene.instantiate()
		helper.position = Vector2(_get_random_x_from_zones(safe_zones), -25)
		roof.add_child(helper)

func _spawn_pickup_safe(roof: Node2D, pickup_type: String, safe_zones: Array, roof_y: float):
	var scene_path = ""
	var min_height = -200
	var max_height = -70
	
	match pickup_type:
		"champagne":
			scene_path = "res://scenes/champagne_pickup.tscn"
		"cocoa":
			scene_path = "res://scenes/cocoa_pickup.tscn"
		"gingerbread":
			scene_path = "res://scenes/gingerbread_pickup.tscn"
		"star":
			scene_path = "res://scenes/star_pickup.tscn"
			min_height = -180
			max_height = -120
		"elf":
			scene_path = "res://scenes/elf_pickup.tscn"
	
	if scene_path == "":
		return
	
	var pickup_scene = load(scene_path)
	if pickup_scene:
		var pickup = pickup_scene.instantiate()
		var x_pos = _get_random_x_from_zones(safe_zones)
		var y_pos = randf_range(min_height, max_height)
		pickup.position = Vector2(x_pos, y_pos)
		roof.add_child(pickup)
