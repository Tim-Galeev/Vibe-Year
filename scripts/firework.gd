extends Area2D

## Салют - повторяющиеся взрывы пока виден

var firework_color: Color = Color.RED
var fuse_time: float = 0.6
var has_exploded: bool = false
var explosion_interval: float = 0.8
var explosion_timer: float = 0.0

func _ready():
	add_to_group("hazard")
	body_entered.connect(_on_body_entered)
	
	var colors = [
		Color(1, 0.2, 0.2),
		Color(1, 0.5, 0.1),
		Color(1, 0.9, 0.2),
		Color(0.2, 1, 0.4),
		Color(0.2, 0.6, 1),
		Color(0.8, 0.2, 1),
	]
	firework_color = colors.pick_random()
	_update_visual()
	
	$CollisionShape2D.disabled = true

func _update_visual():
	if has_node("Visual/Rocket"):
		$Visual/Rocket.color = firework_color.darkened(0.3)
	if has_node("Visual/Tip"):
		$Visual/Tip.color = firework_color

func _physics_process(delta):
	position.x -= GameManager.get_current_scroll_speed() * delta
	
	if not has_exploded:
		fuse_time -= delta
		
		if has_node("Visual/Spark"):
			$Visual/Spark.modulate.a = 0.5 + sin(fuse_time * 25) * 0.5
		
		if fuse_time <= 0:
			_explode()
	else:
		# Повторные взрывы пока виден
		explosion_timer -= delta
		if explosion_timer <= 0:
			explosion_timer = explosion_interval
			_create_explosion()
	
	if global_position.x < -200:
		queue_free()

func _explode():
	has_exploded = true
	$CollisionShape2D.disabled = false
	
	if has_node("Visual/Rocket"):
		$Visual/Rocket.visible = false
	if has_node("Visual/Tip"):
		$Visual/Tip.visible = false
	if has_node("Visual/Spark"):
		$Visual/Spark.visible = false
	
	_create_explosion()
	SoundManager.play_sound("explosion")

func _create_explosion():
	for i in range(25):
		var spark = ColorRect.new()
		var spark_size = randf_range(5, 12)
		spark.size = Vector2(spark_size, spark_size)
		
		if randf() < 0.6:
			spark.color = firework_color
		elif randf() < 0.7:
			spark.color = firework_color.lightened(0.5)
		else:
			spark.color = Color.WHITE
		
		spark.position = Vector2(-spark_size/2, -spark_size/2)
		$Visual.add_child(spark)
		
		var angle = randf() * TAU
		var speed = randf_range(80, 180)
		var target_offset = Vector2(cos(angle), sin(angle)) * speed
		target_offset.y += randf_range(20, 60)
		
		var duration = randf_range(0.6, 1.2)
		var tween = spark.create_tween()
		tween.set_parallel(true)
		tween.tween_property(spark, "position", spark.position + target_offset, duration)
		tween.tween_property(spark, "modulate:a", 0.0, duration)
		tween.set_parallel(false)
		tween.tween_callback(spark.queue_free)
	
	# Вспышка
	var flash = ColorRect.new()
	flash.size = Vector2(80, 80)
	flash.position = Vector2(-40, -40)
	flash.color = Color(1, 1, 0.9, 0.8)
	$Visual.add_child(flash)
	
	var tween = flash.create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.2)
	tween.tween_callback(flash.queue_free)

func _on_body_entered(body):
	if not has_exploded:
		return
	
	if body.is_in_group("sleigh"):
		if body.has_method("take_damage"):
			body.take_damage(1)
		if body.has_method("hit_obstacle"):
			body.hit_obstacle()
