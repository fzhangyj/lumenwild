class_name LumenAudio
extends Node

var music: AudioStreamPlayer
var muted: bool = false
var phase: float = 0.0
var sample_clock: int = 0
var playback: AudioStreamGeneratorPlayback
const NOTES = [220.0, 261.63, 329.63, 392.0, 440.0, 392.0, 329.63, 293.66, 220.0, 293.66, 349.23, 440.0, 523.25, 440.0, 349.23, 293.66]

func _ready() -> void:
	music = AudioStreamPlayer.new()
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = 22050
	stream.buffer_length = 0.15
	music.stream = stream
	music.volume_db = -16
	add_child(music)
	music.play()
	playback = music.get_stream_playback()

func _process(_delta: float) -> void:
	if not is_instance_valid(playback):
		return
	var frames = playback.get_frames_available()
	for i in range(frames):
		var t = float(sample_clock) / 22050
		var beat = int(t / 0.8)
		var local = fmod(t, 0.8)
		var freq: float = NOTES[beat % NOTES.size()]
		var envelope = (1.0 - exp(-local * 26.0)) * exp(-local * 4.2)
		var note = (sin(TAU * freq * t) * 0.14 + sin(TAU * freq * 2 * t) * 0.03) * envelope
		var pad = sin(TAU * 110 * t) * 0.025 + sin(TAU * 164.81 * t) * 0.018
		var sample = (note + pad) * (0.0 if muted else 1.0)
		playback.push_frame(Vector2(sample, sample))
		sample_clock += 1

func tone(frequency: float, duration: float = 0.15, volume: float = 0.23) -> void:
	if muted:
		return
	var player = AudioStreamPlayer.new()
	add_child(player)
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	var bytes = PackedByteArray()
	var count = int(duration * 22050)
	bytes.resize(count * 2)
	for i in range(count):
		var t = float(i) / 22050
		var envelope = sin(PI * float(i) / count) * exp(-t * 10)
		var sample = int(sin(TAU * frequency * t) * envelope * volume * 32760)
		bytes.encode_s16(i * 2, sample)
	wav.data = bytes
	player.stream = wav
	player.play()
	player.finished.connect(player.queue_free)

func _exit_tree() -> void:
	if is_instance_valid(music):
		music.stop()
	playback = null
