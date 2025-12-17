extends Node

## ===============================
##  Sound Manager
##  Mario / Sonic / Rock Christmas
## ===============================

var music_player: AudioStreamPlayer
var sound_players: Dictionary = {}

var music_volume := 0.10
var sfx_volume := 0.60

var music_enabled := true
var sfx_enabled := true


# ========= UTILS =========

func soft_clip(x: float) -> float:
	return x / (1.0 + abs(x))


# ========= INIT =========

func _ready():
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	add_child(music_player)

	for i in range(10):
		var p = AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		sound_players[i] = {"player": p}

	call_deferred("play_music")


# ========= API =========

func play_sound(sound_name: String):
	if not sfx_enabled:
		return

	var p = _get_free_player()
	if p == null:
		return

	var s = _create_sound(sound_name)
	if s:
		p.stream = s
		p.volume_db = linear_to_db(sfx_volume)
		p.play()


func _get_free_player() -> AudioStreamPlayer:
	for k in sound_players:
		var p = sound_players[k]["player"]
		if not p.playing:
			return p
	return sound_players[0]["player"]


func _create_sound(snd_name: String) -> AudioStream:
	match snd_name:
		"chimney_hit": return _generate_coin_sound()
		"throw": return _generate_throw_sound()
		"bounce": return _generate_bounce_sound()
		"damage": return _generate_damage_sound()
		"pickup": return _generate_pickup_sound()
		"boost": return _generate_boost_sound()
		"shield": return _generate_shield_sound()
		"star_power": return _generate_star_sound()
		"star_throw": return _generate_star_throw_sound()
		"tree_launch": return _generate_tree_sound()
		"explosion": return _generate_explosion_sound()
		"ornament_break": return _generate_ornament_sound()
		"game_over": return _generate_gameover_sound()
		_: return _generate_pickup_sound()


# ===============================
#  SFX
# ===============================

func _base_sample() -> AudioStreamWAV:
	var s = AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = 44100
	s.stereo = false
	return s


# --- COIN ---

func _generate_coin_sound() -> AudioStream:
	var s = _base_sample()
	var data = PackedByteArray()
	var length = 0.15
	var samples = int(44100 * length)

	for i in range(samples):
		var t = i / 44100.0
		var env = exp(-t * 12) * (1.0 - exp(-t * 100))
		var freq = 988.0 if t < 0.07 else 1319.0

		var w = sin(t * freq * TAU) * 0.7
		w += sin(t * freq * 2 * TAU) * 0.25
		w += sin(t * freq * 3 * TAU) * 0.15
		w = soft_clip(w * 1.1)

		var v = int(w * env * 32000)
		data.append(v & 0xFF)
		data.append((v >> 8) & 0xFF)

	s.data = data
	return s


# --- THROW ---

func _generate_throw_sound() -> AudioStream:
	var s = _base_sample()
	var data = PackedByteArray()
	var length = 0.1
	var samples = int(44100 * length)

	for i in range(samples):
		var t = i / 44100.0
		var env = exp(-t * 15) * (1.0 - exp(-t * 80))
		var freq = 400 + t * 5000

		var w = sin(t * freq * TAU) * 0.6
		w += sin(t * freq * 0.5 * TAU) * 0.3

		var v = int(w * env * 28000)
		data.append(v & 0xFF)
		data.append((v >> 8) & 0xFF)

	s.data = data
	return s


# --- BOUNCE ---

func _generate_bounce_sound() -> AudioStream:
	var s = _base_sample()
	var data = PackedByteArray()
	var length = 0.25
	var samples = int(44100 * length)

	for i in range(samples):
		var t = i / 44100.0
		var env = exp(-t * 8)
		var freq = 350 + sin(t * 35) * 150 * exp(-t * 5)

		var w = sin(t * freq * TAU) * 0.5
		w += sin(t * freq * 2 * TAU) * 0.3
		w += sin(t * 200 * TAU) * 0.2 * exp(-t * 15)
		w = soft_clip(w * 1.3)

		var v = int(w * env * 30000)
		data.append(v & 0xFF)
		data.append((v >> 8) & 0xFF)

	s.data = data
	return s


# --- DAMAGE ---

func _generate_damage_sound() -> AudioStream:
	var s = _base_sample()
	var data = PackedByteArray()
	var length = 0.35
	var samples = int(44100 * length)

	for i in range(samples):
		var t = i / 44100.0
		var env = exp(-t * 5)
		var freq = 600 - t * 400

		var w = sin(t * freq * TAU) * 0.4
		w += sin(t * freq * 0.5 * TAU) * 0.3
		w += (randf() - 0.5) * 0.35 * exp(-t * 8)
		w = soft_clip(w * 1.2)

		var v = int(w * env * 28000)
		data.append(v & 0xFF)
		data.append((v >> 8) & 0xFF)

	s.data = data
	return s


# --- PICKUP ---

func _generate_pickup_sound() -> AudioStream:
	var s = _base_sample()
	var data = PackedByteArray()
	var length = 0.12
	var samples = int(44100 * length)

	for i in range(samples):
		var t = i / 44100.0
		var env = exp(-t * 15) * (1.0 - exp(-t * 120))
		var freq = 659 + t * 2000

		var w = sin(t * freq * TAU) * 0.6
		w += sin(t * freq * 2 * TAU) * 0.25
		w += sin(t * freq * 3 * TAU) * 0.15

		var v = int(w * env * 30000)
		data.append(v & 0xFF)
		data.append((v >> 8) & 0xFF)

	s.data = data
	return s


# --- BOOST (champagne) ---

func _generate_boost_sound() -> AudioStream:
	var s = _base_sample()
	var data = PackedByteArray()
	var length = 0.35
	var samples = int(44100 * length)

	for i in range(samples):
		var t = i / 44100.0
		var env = sin(t / length * PI) * (1.0 - exp(-t * 20))
		var freq = 300 + t * 800

		var hiss = (randf() - 0.5) * 0.4
		hiss *= smoothstep(0.0, 0.1, t) * exp(-t * 6)

		var w = sin(t * freq * TAU) * 0.4
		w += sin(t * freq * 1.5 * TAU) * 0.25
		w += hiss
		w = soft_clip(w * 1.6)

		var v = int(w * env * 28000)
		data.append(v & 0xFF)
		data.append((v >> 8) & 0xFF)

	s.data = data
	return s


# --- SHIELD (gingerbread crunch) ---

func _generate_shield_sound() -> AudioStream:
	var s = _base_sample()
	var data = PackedByteArray()
	var length = 0.4
	var samples = int(44100 * length)

	for i in range(samples):
		var t = i / 44100.0
		var env = sin(t / length * PI) * (1.0 - exp(-t * 30))

		var crunch = 0.0
		if t < 0.05:
			crunch = (randf() - 0.5) * 0.6 * (1.0 - t / 0.05)

		var w = sin(t * 523 * TAU) * 0.3
		w += sin(t * 659 * TAU) * 0.3
		w += sin(t * 784 * TAU) * 0.25
		w += crunch
		w = soft_clip(w * 1.2)

		var v = int(w * env * 26000)
		data.append(v & 0xFF)
		data.append((v >> 8) & 0xFF)

	s.data = data
	return s


# --- STAR POWER ---

func _generate_star_sound() -> AudioStream:
	var s = _base_sample()
	var data = PackedByteArray()
	var length = 0.5
	var samples = int(44100 * length)

	var notes = [523.0, 659.0, 784.0, 1047.0]
	var note_len = length / 4.0

	for i in range(samples):
		var t = i / 44100.0
		var idx = min(int(t / note_len), 3)
		var nt = fmod(t, note_len)

		var env = (1.0 - exp(-nt * 50)) * exp(-nt * 8)
		var f = notes[idx]

		var w = sin(t * f * TAU) * 0.5
		w += sin(t * f * 2 * TAU) * 0.3
		w += sin(t * f * 3 * TAU) * 0.2

		var v = int(w * env * 28000)
		data.append(v & 0xFF)
		data.append((v >> 8) & 0xFF)

	s.data = data
	return s


# --- STAR THROW ---

func _generate_star_throw_sound() -> AudioStream:
	var s = _base_sample()
	var data = PackedByteArray()
	var length = 0.08
	var samples = int(44100 * length)

	for i in range(samples):
		var t = i / 44100.0
		var env = exp(-t * 25) * (1.0 - exp(-t * 150))

		var w = sin(t * 1500 * TAU) * 0.5
		w += sin(t * 2000 * TAU) * 0.3

		var v = int(w * env * 25000)
		data.append(v & 0xFF)
		data.append((v >> 8) & 0xFF)

	s.data = data
	return s


# --- TREE LAUNCH ---

func _generate_tree_sound() -> AudioStream:
	var s = _base_sample()
	var data = PackedByteArray()
	var length = 0.2
	var samples = int(44100 * length)

	for i in range(samples):
		var t = i / 44100.0
		var env = exp(-t * 10) * (1.0 - exp(-t * 60))

		var w = sin(t * 150 * TAU) * 0.5
		w += sin(t * 100 * TAU) * 0.3
		w += (randf() - 0.5) * 0.2 * exp(-t * 20)

		var v = int(w * env * 30000)
		data.append(v & 0xFF)
		data.append((v >> 8) & 0xFF)

	s.data = data
	return s


# --- EXPLOSION ---

func _generate_explosion_sound() -> AudioStream:
	var s = _base_sample()
	var data = PackedByteArray()
	var length = 0.4
	var samples = int(44100 * length)

	for i in range(samples):
		var t = i / 44100.0
		var env = exp(-t * 6) * (1.0 - exp(-t * 80))

		var w = (randf() - 0.5) * 0.6
		w += sin(t * 60 * TAU) * 0.3 * exp(-t * 8)
		w += sin(t * 40 * TAU) * 0.2 * exp(-t * 5)

		var v = int(w * env * 32000)
		data.append(v & 0xFF)
		data.append((v >> 8) & 0xFF)

	s.data = data
	return s


# --- ORNAMENT BREAK ---

func _generate_ornament_sound() -> AudioStream:
	var s = _base_sample()
	var data = PackedByteArray()
	var length = 0.25
	var samples = int(44100 * length)

	for i in range(samples):
		var t = i / 44100.0
		var env = exp(-t * 12) * (1.0 - exp(-t * 100))

		var w = sin(t * 2500 * TAU) * 0.3
		w += sin(t * 3200 * TAU) * 0.25
		w += sin(t * 4100 * TAU) * 0.2
		w += (randf() - 0.5) * 0.25 * exp(-t * 15)

		var v = int(w * env * 26000)
		data.append(v & 0xFF)
		data.append((v >> 8) & 0xFF)

	s.data = data
	return s


# --- GAME OVER ---

func _generate_gameover_sound() -> AudioStream:
	var s = _base_sample()
	var data = PackedByteArray()
	var length = 0.8
	var samples = int(44100 * length)

	var notes = [392.0, 330.0, 262.0]
	var nl = length / 3.0

	for i in range(samples):
		var t = i / 44100.0
		var idx = min(int(t / nl), 2)
		var nt = fmod(t, nl)

		var env = (1.0 - t / length) * (1.0 - exp(-nt * 30))
		var f = notes[idx]

		var w = sin(t * f * TAU) * 0.5
		w += sin(t * f * 0.5 * TAU) * 0.3

		var v = int(w * env * 26000)
		data.append(v & 0xFF)
		data.append((v >> 8) & 0xFF)

	s.data = data
	return s


# ===============================
#  MUSIC
# ===============================

func play_music():
	if not music_enabled:
		return
	var m = _generate_jingle_bells_full()
	music_player.stream = m
	music_player.volume_db = linear_to_db(music_volume)
	music_player.play()
	music_player.finished.connect(_on_music_finished)


func _on_music_finished():
	if music_enabled:
		music_player.play()


func _generate_jingle_bells_full() -> AudioStream:
	var s = _base_sample()
	var data = PackedByteArray()
	var bpm = 160.0
	var beat = 60.0 / bpm

	var melody = [
		[659,0.5],[659,0.5],[659,1],
		[659,0.5],[659,0.5],[659,1],
		[659,0.5],[784,0.5],[523,0.75],[587,0.25],[659,1.5],[0,0.5],
		[698,0.5],[698,0.5],[698,0.75],[698,0.25],
		[698,0.5],[659,0.5],[659,0.5],[659,0.5],
		[659,0.5],[587,0.5],[587,0.5],[659,0.5],
		[587,1],[784,1],
	]

	var bass_pattern = [262,330,392,330]
	var total_time = 0.0
	for n in melody:
		total_time += n[1] * beat

	var samples = int(44100 * total_time)
	var note_idx = 0
	var note_start = 0.0

	for i in range(samples):
		var t = i / 44100.0

		while note_idx < melody.size() - 1:
			var d = melody[note_idx][1] * beat
			if t >= note_start + d:
				note_start += d
				note_idx += 1
			else:
				break

		var nt = t - note_start
		var freq = melody[note_idx][0]

		var env = (1.0 - exp(-nt * 40)) * exp(-nt * 3)

		var mel = 0.0
		var guitar = 0.0
		if freq > 0:
			mel = sin(t * freq * TAU) * 0.35
			mel += sin(t * freq * 2 * TAU) * 0.15
			mel += sin(t * freq * 3 * TAU) * 0.08

			var saw = 2.0 * fmod(t * freq, 1.0) - 1.0
			guitar = saw * 0.18 * (0.6 + 0.4 * sin(t * 8 * TAU))

		var bass = sin(t * bass_pattern[int(t / beat) % 4] * 0.5 * TAU) * 0.35
		var w = mel * env + guitar + bass
		w = soft_clip(w * 1.4)

		var v = int(w * 28000)
		data.append(v & 0xFF)
		data.append((v >> 8) & 0xFF)

	s.data = data
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	s.loop_begin = 0
	s.loop_end = data.size() / 2
	return s


# ===============================
#  CONTROL
# ===============================

func stop_music(): music_player.stop()

func toggle_music():
	music_enabled = not music_enabled
	if music_enabled: play_music()
	else: stop_music()

func toggle_sfx(): sfx_enabled = not sfx_enabled

func set_music_volume(v: float):
	music_volume = v
	music_player.volume_db = linear_to_db(v)

func set_sfx_volume(v: float):
	sfx_volume = v
