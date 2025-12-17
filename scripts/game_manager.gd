extends Node

## Game Manager - исправленный баланс

signal score_changed(new_score: int)
signal gifts_changed(new_count: int)
signal champagne_changed(new_count: int)
signal tree_charges_changed(new_count: int)
signal lives_changed(new_lives: int)
signal tree_charge_progress(progress: float)
signal game_over
signal game_started
signal speed_boost_started
signal speed_boost_ended
signal invincibility_started
signal invincibility_ended
signal star_power_started
signal star_power_ended
signal score_popup(amount: int, position: Vector2)
signal gift_popup(amount: int, position: Vector2)
signal pickup_fly_to_hud(icon_type: String, from_pos: Vector2)
signal big_announcement(text: String, color: Color)
signal tree_appeared_on_sleigh(slot: int)

var score: int = 0
var high_score: int = 0
var gifts: int = 20
var champagne_bottles: int = 0
var tree_charges: int = 1
var lives: int = 3

var game_speed: float = 1.0
var base_scroll_speed: float = 280.0
var is_game_running: bool = false
var play_time: float = 0.0

# Прогрессия
var total_distance: float = 0.0
var gifts_thrown: int = 0
var lives_lost: int = 0
var first_star_used: bool = false
var last_star_end_time: float = 0.0
var last_chimney_hit_time: float = 0.0  # Для мотивации кидать подарки

# Этапы введения
var intro_cocoa_given: bool = false
var intro_obstacle_added: bool = false
var intro_elf_given: bool = false
var intro_star_given: bool = false
var fireworks_unlocked: bool = false

var intro_cocoa_at_gifts: int = 0
var intro_obstacle_at_gifts: int = 0
var intro_elf_distance: float = 0

var unlocked_bonuses: Array = []
var last_bonus_distance: float = -200
var last_firework_distance: float = -600

# Сложные сегменты
var in_hard_segment: bool = false
var hard_segment_timer: float = 0.0
var cooldown_after_hard: float = 0.0

const MAX_CHAMPAGNE = 3
const MAX_TREE_CHARGES = 3
const MAX_LIVES = 5
const TREE_CHARGE_TIME = 15.0  # Дольше заряжается

# УВЕЛИЧЕННЫЕ расстояния между бонусами
const MIN_DISTANCE_BETWEEN_BONUSES = 120  # Было 50, теперь реже
const MIN_DISTANCE_BETWEEN_FIREWORKS = 400

var _tree_charge_timer: float = 0.0
var _damage_invincible_timer: float = 0.0
var _animation_invincible_timer: float = 0.0

var _speed_boost_timer: float = 0.0
var _slow_timer: float = 0.0
var _invincibility_timer: float = 0.0
var _star_power_timer: float = 0.0

# Нёрф бафов
const SPEED_BOOST_DURATION = 4.0  # Было 6
const SPEED_BOOST_MULTIPLIER = 1.6  # Было 1.8
const SLOW_DURATION = 1.5
const SLOW_MULTIPLIER = 0.6
const INVINCIBILITY_DURATION = 5.0  # Было 8
const STAR_POWER_DURATION = 3.0  # Было 6 - СИЛЬНЫЙ НЁРФ

# Мотивация кидать подарки
const GIFT_DECAY_TIME = 8.0  # Каждые 8 сек без попадания - теряем подарок
var _gift_decay_timer: float = 0.0

var leaderboard: Array = []
const MAX_LEADERBOARD_ENTRIES = 10

func _ready():
	_load_leaderboard()
	reset_game()

func _process(delta):
	if is_game_running:
		play_time += delta
		total_distance += get_current_scroll_speed() * delta / 10.0
		
		game_speed = 1.0 + (play_time / 60.0) * 0.5
		game_speed = min(game_speed, 2.5)
		
		# Зарядка ёлки
		if tree_charges < MAX_TREE_CHARGES:
			_tree_charge_timer += delta
			emit_signal("tree_charge_progress", _tree_charge_timer / TREE_CHARGE_TIME)
			if _tree_charge_timer >= TREE_CHARGE_TIME:
				_tree_charge_timer = 0.0
				add_tree_charge()
		
		# МОТИВАЦИЯ КИДАТЬ - теряем подарки если долго не попадаем
		_gift_decay_timer += delta
		if _gift_decay_timer >= GIFT_DECAY_TIME:
			_gift_decay_timer = 0.0
			if gifts > 5:  # Не отнимаем если мало
				gifts -= 1
				emit_signal("gifts_changed", gifts)
		
		# Сложные сегменты
		if in_hard_segment:
			hard_segment_timer -= delta
			if hard_segment_timer <= 0:
				in_hard_segment = false
				cooldown_after_hard = 5.0  # 5 сек отдыха
		
		if cooldown_after_hard > 0:
			cooldown_after_hard -= delta
		
		# Таймеры
		if _damage_invincible_timer > 0:
			_damage_invincible_timer -= delta
		if _animation_invincible_timer > 0:
			_animation_invincible_timer -= delta
		
		if _speed_boost_timer > 0:
			_speed_boost_timer -= delta
			if _speed_boost_timer <= 0:
				emit_signal("speed_boost_ended")
		
		if _slow_timer > 0:
			_slow_timer -= delta
		
		if _invincibility_timer > 0:
			_invincibility_timer -= delta
			if _invincibility_timer <= 0:
				emit_signal("invincibility_ended")
		
		if _star_power_timer > 0:
			_star_power_timer -= delta
			if _star_power_timer <= 0:
				last_star_end_time = play_time
				first_star_used = true
				emit_signal("star_power_ended")

func reset_game():
	score = 0
	gifts = 20
	champagne_bottles = 0
	tree_charges = 1
	lives = 3
	game_speed = 1.0
	play_time = 0.0
	total_distance = 0.0
	gifts_thrown = 0
	lives_lost = 0
	first_star_used = false
	last_star_end_time = 0.0
	last_chimney_hit_time = 0.0
	_gift_decay_timer = 0.0
	
	intro_cocoa_given = false
	intro_obstacle_added = false
	intro_elf_given = false
	intro_star_given = false
	fireworks_unlocked = false
	
	intro_cocoa_at_gifts = randi_range(3, 6)
	intro_obstacle_at_gifts = intro_cocoa_at_gifts + randi_range(3, 5)
	intro_elf_distance = randf_range(400, 600)
	
	unlocked_bonuses.clear()
	last_bonus_distance = -200
	last_firework_distance = -600
	
	in_hard_segment = false
	hard_segment_timer = 0.0
	cooldown_after_hard = 0.0
	
	_tree_charge_timer = 0.0
	_damage_invincible_timer = 0.0
	_animation_invincible_timer = 0.0
	_speed_boost_timer = 0.0
	_slow_timer = 0.0
	_invincibility_timer = 0.0
	_star_power_timer = 0.0
	is_game_running = false
	
	emit_signal("score_changed", score)
	emit_signal("gifts_changed", gifts)
	emit_signal("champagne_changed", champagne_bottles)
	emit_signal("tree_charges_changed", tree_charges)
	emit_signal("lives_changed", lives)
	emit_signal("tree_charge_progress", 0.0)

func start_game():
	reset_game()
	is_game_running = true
	emit_signal("game_started")

func end_game():
	is_game_running = false
	if score > high_score:
		high_score = score
	SoundManager.play_sound("game_over")
	emit_signal("game_over")

# ========== ОЧКИ ==========

func add_score(amount: int, pos: Vector2 = Vector2.ZERO):
	score += amount
	emit_signal("score_changed", score)
	if pos != Vector2.ZERO and amount > 0:
		emit_signal("score_popup", amount, pos)

# При попадании в дымоход - сбрасываем таймер decay
func on_chimney_hit():
	_gift_decay_timer = 0.0
	last_chimney_hit_time = play_time

# ========== ПОДАРКИ ==========

func add_gift():
	gifts += 1
	emit_signal("gifts_changed", gifts)

func add_gifts(amount: int, pos: Vector2 = Vector2.ZERO):
	gifts += amount
	emit_signal("gifts_changed", gifts)
	if pos != Vector2.ZERO:
		emit_signal("gift_popup", amount, pos)
		emit_signal("pickup_fly_to_hud", "gift", pos)

func use_gift() -> bool:
	if gifts > 0:
		gifts -= 1
		gifts_thrown += 1
		emit_signal("gifts_changed", gifts)
		
		if gifts <= 0:
			call_deferred("end_game")
		return true
	return false

# ========== БОНУСЫ ==========

func add_champagne(from_pos: Vector2 = Vector2.ZERO):
	if champagne_bottles < MAX_CHAMPAGNE:
		champagne_bottles += 1
		emit_signal("champagne_changed", champagne_bottles)
		if from_pos != Vector2.ZERO:
			emit_signal("pickup_fly_to_hud", "champagne", from_pos)
	add_score(5, from_pos)

func use_champagne() -> bool:
	if champagne_bottles > 0:
		champagne_bottles -= 1
		emit_signal("champagne_changed", champagne_bottles)
		activate_speed_boost()
		emit_signal("big_announcement", "УСКОРЕНИЕ!", Color(0.3, 1, 0.5))
		start_animation_invincibility()
		return true
	return false

func add_tree_charge():
	if tree_charges < MAX_TREE_CHARGES:
		tree_charges += 1
		emit_signal("tree_charges_changed", tree_charges)
		emit_signal("tree_appeared_on_sleigh", tree_charges)

func use_tree_charge() -> bool:
	if tree_charges > 0:
		tree_charges -= 1
		_tree_charge_timer = 0.0
		emit_signal("tree_charges_changed", tree_charges)
		emit_signal("tree_charge_progress", 0.0)
		return true
	return false

# ========== ЗДОРОВЬЕ ==========

func take_damage(amount: int = 1) -> bool:
	if _damage_invincible_timer > 0 or _invincibility_timer > 0 or _animation_invincible_timer > 0:
		return false
	
	lives -= amount
	lives_lost += amount
	emit_signal("lives_changed", lives)
	
	_damage_invincible_timer = 1.5
	
	if lives <= 0:
		end_game()
		return true
	return false

func heal(amount: int = 1, from_pos: Vector2 = Vector2.ZERO):
	lives = min(lives + amount, MAX_LIVES)
	emit_signal("lives_changed", lives)
	if from_pos != Vector2.ZERO:
		emit_signal("pickup_fly_to_hud", "heart", from_pos)
	add_score(5, from_pos)

func is_damage_invincible() -> bool:
	return _damage_invincible_timer > 0

func is_animation_invincible() -> bool:
	return _animation_invincible_timer > 0

func is_invincible() -> bool:
	return _invincibility_timer > 0

func is_any_invincible() -> bool:
	return _damage_invincible_timer > 0 or _invincibility_timer > 0 or _animation_invincible_timer > 0

# ========== БАФЫ ==========

func start_animation_invincibility():
	_animation_invincible_timer = 1.0

func activate_speed_boost():
	_speed_boost_timer = SPEED_BOOST_DURATION
	_slow_timer = 0
	emit_signal("speed_boost_started")

func activate_slow():
	if not is_speed_boosted():
		_slow_timer = SLOW_DURATION

func activate_invincibility(from_pos: Vector2 = Vector2.ZERO):
	_invincibility_timer = INVINCIBILITY_DURATION
	emit_signal("invincibility_started")
	emit_signal("big_announcement", "НЕУЯЗВИМОСТЬ!", Color(0.5, 0.8, 1))
	start_animation_invincibility()
	add_score(5, from_pos)

func activate_star_power(from_pos: Vector2 = Vector2.ZERO):
	_star_power_timer = STAR_POWER_DURATION
	emit_signal("star_power_started")
	emit_signal("big_announcement", "ЗВЕЗДА!", Color(1, 0.9, 0.3))
	start_animation_invincibility()
	add_score(10, from_pos)

func is_speed_boosted() -> bool:
	return _speed_boost_timer > 0

func is_slowed() -> bool:
	return _slow_timer > 0

func is_star_power_active() -> bool:
	return _star_power_timer > 0

func get_current_scroll_speed() -> float:
	var speed = base_scroll_speed * game_speed
	if is_speed_boosted():
		speed *= SPEED_BOOST_MULTIPLIER
	elif is_slowed():
		speed *= SLOW_MULTIPLIER
	return speed

func get_speed_boost_time_left() -> float:
	return _speed_boost_timer

func get_invincibility_time_left() -> float:
	return _invincibility_timer

func get_star_power_time_left() -> float:
	return _star_power_timer

func get_tree_charge_progress() -> float:
	return _tree_charge_timer / TREE_CHARGE_TIME

# ========== ПРОГРЕССИЯ ==========

func should_spawn_intro_cocoa() -> bool:
	if intro_cocoa_given:
		return false
	return gifts_thrown >= intro_cocoa_at_gifts

func mark_intro_cocoa_given():
	intro_cocoa_given = true
	if "cocoa" not in unlocked_bonuses:
		unlocked_bonuses.append("cocoa")

func should_spawn_intro_obstacle() -> bool:
	if intro_obstacle_added:
		return false
	return gifts_thrown >= intro_obstacle_at_gifts

func mark_intro_obstacle_added():
	intro_obstacle_added = true

func should_spawn_intro_elf() -> bool:
	if intro_elf_given:
		return false
	if gifts < 8:
		return true
	return intro_obstacle_added and total_distance >= intro_elf_distance

func mark_intro_elf_given():
	intro_elf_given = true
	if "elf" not in unlocked_bonuses:
		unlocked_bonuses.append("elf")

func should_spawn_first_star() -> bool:
	if intro_star_given:
		return false
	return score >= 1500  # Было 1000

func mark_first_star_given():
	intro_star_given = true
	if "star" not in unlocked_bonuses:
		unlocked_bonuses.append("star")

func can_spawn_fireworks() -> bool:
	if not first_star_used:
		return false
	if is_star_power_active():
		return false
	if play_time - last_star_end_time < 3.0:
		return false
	if total_distance - last_firework_distance < MIN_DISTANCE_BETWEEN_FIREWORKS:
		return false
	return true

func register_firework_spawn():
	last_firework_distance = total_distance

func can_spawn_bonus() -> bool:
	return total_distance - last_bonus_distance >= MIN_DISTANCE_BETWEEN_BONUSES

func register_bonus_spawn(bonus_type: String):
	last_bonus_distance = total_distance

func unlock_bonus(bonus_type: String):
	if bonus_type not in unlocked_bonuses:
		unlocked_bonuses.append(bonus_type)

# ========== СЛОЖНЫЕ СЕГМЕНТЫ ==========

func start_hard_segment(duration: float = 4.0):
	in_hard_segment = true
	hard_segment_timer = duration

func is_in_hard_segment() -> bool:
	return in_hard_segment

func is_in_cooldown() -> bool:
	return cooldown_after_hard > 0

# ========== ТАБЛИЦА РЕКОРДОВ ==========

func _load_leaderboard():
	if FileAccess.file_exists("user://leaderboard.json"):
		var file = FileAccess.open("user://leaderboard.json", FileAccess.READ)
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			leaderboard = json.get_data()
		file.close()

func _save_leaderboard():
	var file = FileAccess.open("user://leaderboard.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(leaderboard))
	file.close()

func add_to_leaderboard(player_name: String, player_score: int):
	leaderboard.append({"name": player_name, "score": player_score})
	leaderboard.sort_custom(func(a, b): return a["score"] > b["score"])
	if leaderboard.size() > MAX_LEADERBOARD_ENTRIES:
		leaderboard.resize(MAX_LEADERBOARD_ENTRIES)
	_save_leaderboard()

func is_high_score(player_score: int) -> bool:
	if leaderboard.size() < MAX_LEADERBOARD_ENTRIES:
		return true
	return player_score > leaderboard[-1]["score"]

func get_leaderboard() -> Array:
	return leaderboard
