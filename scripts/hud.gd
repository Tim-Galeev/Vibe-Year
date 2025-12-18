extends CanvasLayer

## HUD - с комбо-индикатором

@onready var center_hud = $CenterHUD
@onready var score_label = $CenterHUD/ScoreContainer/ScoreLabel
@onready var champagne_label = $CenterHUD/ChampagneContainer/Label
@onready var tree_label = $CenterHUD/TreeContainer/Top/Label
@onready var tree_progress = $CenterHUD/TreeContainer/TreeProgress
@onready var gifts_label = $CenterHUD/GiftsContainer/Label
@onready var lives_label = $CenterHUD/LivesContainer/Label

@onready var buffs_label = $BuffsLabel
@onready var announcement_label = $AnnouncementLabel
@onready var combo_label = $ComboLabel

@onready var game_over_panel = $GameOverPanel
@onready var final_score_label = $GameOverPanel/VBoxContainer/FinalScoreLabel
@onready var name_input = $GameOverPanel/VBoxContainer/NameInput
@onready var save_score_button = $GameOverPanel/VBoxContainer/SaveScoreButton
@onready var leaderboard_container = $GameOverPanel/VBoxContainer/LeaderboardContainer
@onready var restart_button = $GameOverPanel/VBoxContainer/RestartButton

@onready var start_panel = $StartPanel
@onready var start_button = $StartPanel/VBoxContainer/StartButton
@onready var music_button = $StartPanel/VBoxContainer/HBoxContainer/MusicButton
@onready var sfx_button = $StartPanel/VBoxContainer/HBoxContainer/SFXButton
@onready var leaderboard_start = $StartPanel/VBoxContainer/LeaderboardStart

@onready var sound_buttons = $SoundButtons
@onready var music_toggle = $SoundButtons/MusicToggle
@onready var sfx_toggle = $SoundButtons/SFXToggle
@onready var touch_controls = $TouchControls
@onready var champagne_button = $TouchControls/ChampagneButton
@onready var tree_button = $TouchControls/TreeButton

var popup_container: Node2D
var menu_buttons: Array = []
var current_button_index: int = 0
var _joy_pressed: bool = false
var _game_over_reason: String = ""

func _ready():
	# Сигналы GameManager
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.gifts_changed.connect(_on_gifts_changed)
	GameManager.champagne_changed.connect(_on_champagne_changed)
	GameManager.tree_charges_changed.connect(_on_tree_charges_changed)
	GameManager.lives_changed.connect(_on_lives_changed)
	GameManager.tree_charge_progress.connect(_on_tree_progress)
	GameManager.game_over.connect(_on_game_over)
	GameManager.game_started.connect(_on_game_started)
	GameManager.speed_boost_started.connect(_on_bonus_update)
	GameManager.speed_boost_ended.connect(_on_bonus_update)
	GameManager.invincibility_started.connect(_on_bonus_update)
	GameManager.invincibility_ended.connect(_on_bonus_update)
	GameManager.star_power_started.connect(_on_bonus_update)
	GameManager.star_power_ended.connect(_on_bonus_update)
	GameManager.score_popup.connect(_on_score_popup)
	GameManager.gift_popup.connect(_on_gift_popup)
	GameManager.pickup_fly_to_hud.connect(_on_pickup_fly)
	GameManager.big_announcement.connect(_on_big_announcement)
	GameManager.tree_appeared_on_sleigh.connect(_on_tree_appeared)
	GameManager.combo_changed.connect(_on_combo_changed)
	GameManager.game_over_reason.connect(_on_game_over_reason)
	
	popup_container = Node2D.new()
	popup_container.z_index = 100
	get_tree().root.call_deferred("add_child", popup_container)
	
	if announcement_label:
		announcement_label.visible = false
	
	if combo_label:
		combo_label.visible = false
	
	call_deferred("_connect_buttons")
	call_deferred("_setup_initial_state")

func _connect_buttons():
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)
	if start_button:
		start_button.pressed.connect(_on_start_pressed)
	if save_score_button:
		save_score_button.pressed.connect(_on_save_score_pressed)
	
	var mb = get_node_or_null("StartPanel/VBoxContainer/HBoxContainer/MusicButton")
	var sb = get_node_or_null("StartPanel/VBoxContainer/HBoxContainer/SFXButton")
	
	if mb:
		mb.pressed.connect(_on_music_toggle)
	if sb:
		sb.pressed.connect(_on_sfx_toggle)
	
	# Сенсорные кнопки
	if champagne_button:
		champagne_button.pressed.connect(_on_champagne_touch)
	if tree_button:
		tree_button.pressed.connect(_on_tree_touch)
	
	# Кнопки звука в игре
	if music_toggle:
		music_toggle.pressed.connect(_on_music_toggle)
	if sfx_toggle:
		sfx_toggle.pressed.connect(_on_sfx_toggle)

func _process(_delta):
	if GameManager.is_game_running:
		_update_buffs_display()
	else:
		_handle_menu_input()

func _handle_menu_input():
	var joy_y = Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
	var dpad_up = Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_UP)
	var dpad_down = Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_DOWN)
	
	if not _joy_pressed:
		if joy_y < -0.5 or dpad_up:
			_navigate_menu(-1)
			_joy_pressed = true
		elif joy_y > 0.5 or dpad_down:
			_navigate_menu(1)
			_joy_pressed = true
		
		if Input.is_joy_button_pressed(0, JOY_BUTTON_A):
			_confirm_menu()
			_joy_pressed = true
	else:
		if abs(joy_y) < 0.3 and not dpad_up and not dpad_down and not Input.is_joy_button_pressed(0, JOY_BUTTON_A):
			_joy_pressed = false

func _navigate_menu(direction: int):
	if menu_buttons.size() == 0:
		return
	
	current_button_index = (current_button_index + direction) % menu_buttons.size()
	if current_button_index < 0:
		current_button_index = menu_buttons.size() - 1
	
	_highlight_current_button()

func _highlight_current_button():
	for i in range(menu_buttons.size()):
		var btn = menu_buttons[i]
		if is_instance_valid(btn):
			if i == current_button_index:
				btn.grab_focus()

func _confirm_menu():
	if menu_buttons.size() > 0 and current_button_index < menu_buttons.size():
		var btn = menu_buttons[current_button_index]
		if is_instance_valid(btn) and btn.visible:
			btn.emit_signal("pressed")

func _setup_initial_state():
	update_all_labels()
	_update_sound_buttons()
	_update_leaderboard_display()
	show_start_screen()

func _update_sound_buttons():
	var mb = get_node_or_null("StartPanel/VBoxContainer/HBoxContainer/MusicButton")
	var sb = get_node_or_null("StartPanel/VBoxContainer/HBoxContainer/SFXButton")
	
	if mb:
		mb.text = "🎵 ВКЛ" if SoundManager.music_enabled else "🎵 ВЫКЛ"
	if sb:
		sb.text = "🔊 ВКЛ" if SoundManager.sfx_enabled else "🔊 ВЫКЛ"
	
	# Кнопки в игре
	if music_toggle:
		music_toggle.text = "🎵" if SoundManager.music_enabled else "🎵❌"
	if sfx_toggle:
		sfx_toggle.text = "🔊" if SoundManager.sfx_enabled else "🔊❌"

func _on_music_toggle():
	SoundManager.toggle_music()
	_update_sound_buttons()

func _on_sfx_toggle():
	SoundManager.toggle_sfx()
	_update_sound_buttons()

func update_all_labels():
	_on_score_changed(GameManager.score)
	_on_gifts_changed(GameManager.gifts)
	_on_champagne_changed(GameManager.champagne_bottles)
	_on_tree_charges_changed(GameManager.tree_charges)
	_on_lives_changed(GameManager.lives)

func _on_score_changed(new_score: int):
	if score_label:
		score_label.text = str(new_score)

func _on_gifts_changed(new_count: int):
	if gifts_label:
		gifts_label.text = str(new_count)
		
		var container = gifts_label.get_parent()
		if container:
			if new_count <= 5:
				container.modulate = Color.RED
			elif new_count <= 10:
				container.modulate = Color.YELLOW
			else:
				container.modulate = Color.WHITE

func _on_lives_changed(new_lives: int):
	if lives_label:
		lives_label.text = "❤️".repeat(new_lives) + "🖤".repeat(max(0, 3 - new_lives))

func _on_champagne_changed(new_count: int):
	if champagne_label:
		champagne_label.text = str(new_count)

func _on_tree_charges_changed(new_count: int):
	if tree_label:
		tree_label.text = str(new_count)

func _on_tree_progress(progress: float):
	if tree_progress:
		tree_progress.value = progress * 100

func _on_combo_changed(combo: int, _multiplier: float):
	if not combo_label:
		return
	
	if combo >= 2:
		combo_label.text = "🔥 x%d" % combo
		combo_label.visible = true
		
		# Анимация при увеличении комбо
		var tween = combo_label.create_tween()
		tween.tween_property(combo_label, "scale", Vector2(1.3, 1.3), 0.1)
		tween.tween_property(combo_label, "scale", Vector2(1.0, 1.0), 0.1)
		
		# Цвет в зависимости от комбо
		if combo >= 15:
			combo_label.add_theme_color_override("font_color", Color(1, 0.3, 0.1))  # Красный
		elif combo >= 10:
			combo_label.add_theme_color_override("font_color", Color(1, 0.6, 0.1))  # Оранжевый
		elif combo >= 5:
			combo_label.add_theme_color_override("font_color", Color(1, 0.9, 0.2))  # Жёлтый
		else:
			combo_label.add_theme_color_override("font_color", Color(0.8, 1, 0.3))  # Зелёный
	else:
		combo_label.visible = false

func _on_bonus_update():
	_update_buffs_display()

func _update_buffs_display():
	if not buffs_label:
		return
	
	var buffs = []
	
	if GameManager.is_speed_boosted():
		buffs.append("🍾 %.1fs" % GameManager.get_speed_boost_time_left())
	
	if GameManager.is_invincible():
		buffs.append("❄️ %.1fs" % GameManager.get_invincibility_time_left())
	
	if GameManager.is_star_power_active():
		buffs.append("⭐ %.1fs" % GameManager.get_star_power_time_left())
	
	if buffs.size() > 0:
		buffs_label.text = " | ".join(buffs)
		buffs_label.visible = true
	else:
		buffs_label.visible = false

func _on_score_popup(amount: int, pos: Vector2):
	if not popup_container or amount == 0:
		return
	
	var popup = Label.new()
	popup.text = ("+" if amount > 0 else "") + str(amount)
	popup.add_theme_font_size_override("font_size", 24)
	
	# Цвет зависит от комбо
	var combo = GameManager.get_combo_count()
	if combo >= 10:
		popup.add_theme_color_override("font_color", Color(1, 0.3, 0.1))
	elif combo >= 5:
		popup.add_theme_color_override("font_color", Color(1, 0.7, 0.1))
	else:
		popup.add_theme_color_override("font_color", Color.GREEN if amount > 0 else Color.GRAY)
	
	popup.global_position = pos + Vector2(-20, -30)
	popup_container.add_child(popup)
	
	var tween = popup.create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "global_position:y", popup.global_position.y - 60, 1.0)
	tween.tween_property(popup, "modulate:a", 0.0, 1.0)
	tween.set_parallel(false)
	tween.tween_callback(popup.queue_free)

func _on_gift_popup(amount: int, pos: Vector2):
	if not popup_container:
		return
	
	var popup = Label.new()
	popup.text = "+" + str(amount) + "🎁"
	popup.add_theme_font_size_override("font_size", 28)
	popup.add_theme_color_override("font_color", Color.GOLD)
	popup.global_position = pos + Vector2(-35, -30)
	popup_container.add_child(popup)
	
	var tween = popup.create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "global_position:y", popup.global_position.y - 70, 1.2)
	tween.tween_property(popup, "modulate:a", 0.0, 1.2)
	tween.set_parallel(false)
	tween.tween_callback(popup.queue_free)

func _on_pickup_fly(icon_type: String, from_pos: Vector2):
	if not popup_container:
		return
	
	var icon = Label.new()
	icon.add_theme_font_size_override("font_size", 36)
	
	var target_pos = Vector2(640, 30)
	
	match icon_type:
		"heart":
			icon.text = "❤️"
			target_pos = Vector2(900, 30)
		"champagne":
			icon.text = "🍾"
			target_pos = Vector2(450, 30)
		"gift":
			icon.text = "🎁"
			target_pos = Vector2(780, 30)
		"tree":
			icon.text = "🎄"
			target_pos = Vector2(550, 30)
	
	icon.global_position = from_pos
	popup_container.add_child(icon)
	
	var tween = icon.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(icon, "global_position", target_pos, 0.6)
	tween.parallel().tween_property(icon, "scale", Vector2(0.5, 0.5), 0.6)
	tween.tween_callback(icon.queue_free)

func _on_big_announcement(text: String, color: Color):
	if not announcement_label:
		return
	
	announcement_label.text = text
	announcement_label.add_theme_color_override("font_color", color)
	announcement_label.visible = true
	announcement_label.scale = Vector2(0.5, 0.5)
	announcement_label.modulate.a = 1.0
	
	var tween = announcement_label.create_tween()
	tween.tween_property(announcement_label, "scale", Vector2(1.2, 1.2), 0.2)
	tween.tween_property(announcement_label, "scale", Vector2(1.0, 1.0), 0.1)
	tween.tween_interval(1.0)
	tween.tween_property(announcement_label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): announcement_label.visible = false)

func _on_tree_appeared(_slot: int):
	pass

func _on_game_over_reason(reason: String):
	_game_over_reason = reason

func _on_game_over():
	if game_over_panel:
		game_over_panel.visible = true
	if final_score_label:
		if _game_over_reason != "":
			final_score_label.text = "%s\nСчёт: %d" % [_game_over_reason, GameManager.score]
		else:
			final_score_label.text = "Счёт: %d" % GameManager.score
	if name_input:
		name_input.text = ""
		name_input.visible = GameManager.is_high_score(GameManager.score)
	if save_score_button:
		save_score_button.visible = GameManager.is_high_score(GameManager.score)
	if sound_buttons:
		sound_buttons.visible = false
	if combo_label:
		combo_label.visible = false
	if touch_controls:
		touch_controls.visible = false
	
	menu_buttons = [restart_button]
	if save_score_button and save_score_button.visible:
		menu_buttons.insert(0, save_score_button)
	current_button_index = 0
	_highlight_current_button()
	
	_update_leaderboard_display()

func _on_game_started():
	if start_panel:
		start_panel.visible = false
	if game_over_panel:
		game_over_panel.visible = false
	if sound_buttons:
		sound_buttons.visible = true
	if touch_controls:
		touch_controls.visible = true
	menu_buttons.clear()

func show_start_screen():
	if start_panel:
		start_panel.visible = true
	if game_over_panel:
		game_over_panel.visible = false
	if sound_buttons:
		sound_buttons.visible = false
	if combo_label:
		combo_label.visible = false
	if touch_controls:
		touch_controls.visible = false
	
	var mb = get_node_or_null("StartPanel/VBoxContainer/HBoxContainer/MusicButton")
	var sb = get_node_or_null("StartPanel/VBoxContainer/HBoxContainer/SFXButton")
	var stb = get_node_or_null("StartPanel/VBoxContainer/StartButton")
	
	menu_buttons = []
	if mb: menu_buttons.append(mb)
	if sb: menu_buttons.append(sb)
	if stb: menu_buttons.append(stb)
	
	current_button_index = menu_buttons.size() - 1
	_highlight_current_button()
	
	_update_leaderboard_display()

func _on_restart_pressed():
	get_tree().reload_current_scene()

func _on_start_pressed():
	GameManager.start_game()

func _on_save_score_pressed():
	if name_input and name_input.text.strip_edges() != "":
		GameManager.add_to_leaderboard(name_input.text.strip_edges(), GameManager.score)
		name_input.visible = false
		save_score_button.visible = false
		_update_leaderboard_display()

func _update_leaderboard_display():
	if leaderboard_start:
		for child in leaderboard_start.get_children():
			child.queue_free()
		
		var title = Label.new()
		title.text = "🏆 РЕКОРДЫ"
		title.add_theme_font_size_override("font_size", 16)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		leaderboard_start.add_child(title)
		
		var board = GameManager.get_leaderboard()
		for i in range(min(board.size(), 5)):
			var entry = Label.new()
			entry.text = "%d. %s - %d" % [i + 1, board[i]["name"], board[i]["score"]]
			entry.add_theme_font_size_override("font_size", 12)
			entry.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			leaderboard_start.add_child(entry)
	
	if leaderboard_container:
		for child in leaderboard_container.get_children():
			child.queue_free()
		
		var board = GameManager.get_leaderboard()
		for i in range(min(board.size(), 5)):
			var entry = Label.new()
			entry.text = "%d. %s - %d" % [i + 1, board[i]["name"], board[i]["score"]]
			entry.add_theme_font_size_override("font_size", 14)
			entry.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			leaderboard_container.add_child(entry)

# Сенсорные кнопки
func _on_champagne_touch():
	if GameManager.is_game_running:
		if GameManager.use_champagne():
			SoundManager.play_sound("boost")

func _on_tree_touch():
	if GameManager.is_game_running:
		var sleigh = get_tree().get_first_node_in_group("sleigh")
		if sleigh and sleigh.has_method("use_tree_grenade"):
			sleigh.use_tree_grenade()
