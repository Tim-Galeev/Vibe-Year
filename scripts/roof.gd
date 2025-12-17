extends Node2D

## Крыша / Здание - платформа с визуалом города

var roof_width: float = 300.0
var building_height: float = 300.0
var has_garland: bool = false

@onready var roof_rect: ColorRect = $RoofRect
@onready var roof_top: ColorRect = $RoofTop
@onready var snow: ColorRect = $Snow
@onready var building_body: ColorRect = $BuildingBody
@onready var collision_shape: CollisionShape2D = $StaticBody2D/CollisionShape2D
@onready var chimney_container: Node2D = $ChimneyContainer
@onready var obstacle_container: Node2D = $ObstacleContainer

var building_colors = [
	Color(0.25, 0.22, 0.3),
	Color(0.3, 0.25, 0.2),
	Color(0.22, 0.25, 0.32),
	Color(0.28, 0.28, 0.25),
	Color(0.35, 0.28, 0.22),
]

var garland_colors = [Color.RED, Color.GREEN, Color.GOLD, Color.CYAN, Color.MAGENTA, Color.WHITE]

func _ready():
	add_to_group("roof")
	
	var color = building_colors.pick_random()
	if building_body:
		building_body.color = color
	if roof_rect:
		roof_rect.color = color.lightened(0.1)
	
	_update_collision()

func set_width(width: float):
	roof_width = width
	
	if roof_rect:
		roof_rect.size.x = width
	if roof_top:
		roof_top.size.x = width
	if snow:
		snow.size.x = width
	if building_body:
		building_body.size.x = width
	
	_update_collision()
	
	if has_garland:
		_create_garland()

func set_building_height(height: float):
	building_height = height
	
	if building_body:
		building_body.size.y = height
		building_body.position.y = 20
	
	_add_windows()

func _add_windows():
	for child in get_children():
		if child.is_in_group("window"):
			child.queue_free()
	
	if not building_body:
		return
	
	var window_rows = int(building_height / 50)
	var window_cols = int(roof_width / 45)
	
	for row in range(min(window_rows, 8)):
		for col in range(min(window_cols, 6)):
			if randf() < 0.7:
				var window = ColorRect.new()
				window.size = Vector2(20, 25)
				window.position = Vector2(15 + col * 45, 40 + row * 50)
				if randf() < 0.6:
					window.color = Color(1, 0.9, 0.5, 0.8)
				else:
					window.color = Color(0.15, 0.18, 0.25, 0.9)
				window.add_to_group("window")
				add_child(window)

func _update_collision():
	if collision_shape:
		if not collision_shape.shape:
			collision_shape.shape = RectangleShape2D.new()
		if collision_shape.shape is RectangleShape2D:
			var shape = collision_shape.shape as RectangleShape2D
			shape.size = Vector2(roof_width, 40)
		collision_shape.position = Vector2(roof_width / 2, 20)

func get_width() -> float:
	return roof_width

func add_garland():
	has_garland = true

func _create_garland():
	# Гирлянда на крыше
	var garland_y = -5
	var lights_count = int(roof_width / 25)
	
	# Провод
	var wire = ColorRect.new()
	wire.size = Vector2(roof_width - 20, 2)
	wire.position = Vector2(10, garland_y)
	wire.color = Color(0.2, 0.2, 0.2)
	wire.add_to_group("garland")
	add_child(wire)
	
	# Лампочки
	for i in range(lights_count):
		var light = ColorRect.new()
		light.size = Vector2(8, 12)
		light.position = Vector2(15 + i * 25, garland_y - 2)
		light.color = garland_colors[i % garland_colors.size()]
		light.add_to_group("garland")
		add_child(light)
		
		# Анимация мерцания
		var tween = light.create_tween()
		tween.set_loops()
		tween.tween_property(light, "modulate:a", 0.4, randf_range(0.3, 0.6))
		tween.tween_property(light, "modulate:a", 1.0, randf_range(0.3, 0.6))

func add_chimney(x_pos: float):
	if not chimney_container:
		return
	var chimney_scene = preload("res://scenes/chimney.tscn")
	var chimney = chimney_scene.instantiate()
	chimney.position = Vector2(x_pos, 0)
	chimney_container.add_child(chimney)

func add_blocker():
	if not chimney_container:
		return
	for chimney in chimney_container.get_children():
		if chimney.has_method("add_blocker"):
			chimney.add_blocker()
			break
