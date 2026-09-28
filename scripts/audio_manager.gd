extends Node

const MUSIC_STREAM: AudioStreamMP3 = preload("res://assets/audio/foxglove_workshop.mp3")

var music_player: AudioStreamPlayer
var click_stream: AudioStreamWAV
var hover_stream: AudioStreamWAV
var inspect_stream: AudioStreamWAV
var reward_stream: AudioStreamWAV
var transition_stream: AudioStreamWAV
var can_play := true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	can_play = DisplayServer.get_name() != "headless"
	ensure_bus("Music")
	ensure_bus("SFX")
	click_stream = create_tone([520.0, 780.0], 0.09, 0.18, 14.0)
	hover_stream = create_tone([690.0], 0.045, 0.07, 24.0)
	inspect_stream = create_tone([587.0, 880.0], 0.24, 0.16, 7.0)
	reward_stream = create_tone([523.25, 659.25, 783.99], 0.72, 0.18, 3.4)
	transition_stream = create_tone([246.94, 369.99], 0.20, 0.11, 8.0)
	if can_play:
		music_player = AudioStreamPlayer.new()
		music_player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
		music_player.bus = "Music"
		var looped_music := MUSIC_STREAM.duplicate() as AudioStreamMP3
		looped_music.loop = true
		music_player.stream = looped_music
		add_child(music_player)
		music_player.play()
	GameState.apply_settings()


func ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)


func create_tone(frequencies: Array, duration: float, volume: float, decay: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var sample_count := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for index in range(sample_count):
		var time := float(index) / sample_rate
		var envelope := exp(-time * decay) * minf(1.0, time * 90.0)
		var sample := 0.0
		for frequency in frequencies:
			sample += sin(TAU * float(frequency) * time)
		sample = sample / maxf(1.0, frequencies.size()) * volume * envelope
		data.encode_s16(index * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream


func play_stream(stream: AudioStreamWAV) -> void:
	if not can_play or stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	player.bus = "SFX"
	player.stream = stream
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


func play_click() -> void:
	play_stream(click_stream)


func play_hover() -> void:
	play_stream(hover_stream)


func play_inspect() -> void:
	play_stream(inspect_stream)


func play_reward() -> void:
	play_stream(reward_stream)


func play_transition() -> void:
	play_stream(transition_stream)
