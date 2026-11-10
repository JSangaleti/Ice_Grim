extends Node
## Gerencia música e efeitos sem escolher arquivos ou eventos do jogo.

const MASTER_BUS: StringName = &"Master"
const MUSIC_BUS: StringName = &"Music"
const SFX_BUS: StringName = &"SFX"
const MAX_SFX_PLAYERS: int = 16

var _music_player: AudioStreamPlayer
var _music_source: AudioStream
var _sfx_players: Array[AudioStreamPlayer] = []


func _ready() -> void:
	# Permite manter a música e tocar sons de menus com o jogo pausado.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.bus = MUSIC_BUS
	add_child(_music_player)


## Troca a música imediatamente. A mesma faixa continua, salvo restart = true.
func play_music(stream: AudioStream, looped: bool = true, restart: bool = false) -> void:
	if stream == null:
		push_warning("AudioManager: informe um AudioStream para tocar música.")
		return

	if _music_source == stream and not restart:
		if _music_player.playing or _music_player.stream_paused:
			_set_stream_loop(_music_player.stream, looped)
			return

	_music_source = stream
	# Não altera o recurso compartilhado com outros players ou cenas.
	_music_player.stream = stream.duplicate() as AudioStream
	_set_stream_loop(_music_player.stream, looped)
	_music_player.stream_paused = false
	_music_player.play()


func stop_music() -> void:
	_music_player.stop()
	_music_player.stream_paused = false
	_music_player.stream = null
	_music_source = null


func pause_music() -> void:
	if _music_player.playing:
		_music_player.stream_paused = true


func resume_music() -> void:
	_music_player.stream_paused = false


## Cada chamada toca uma vez, permitindo sobreposição de efeitos diferentes.
func play_sfx(stream: AudioStream, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	if stream == null or pitch_scale <= 0.0:
		push_warning("AudioManager: informe um AudioStream e pitch_scale maior que zero.")
		return

	var player := _get_sfx_player()
	player.stream = stream.duplicate() as AudioStream
	_set_stream_loop(player.stream, false)
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.stream_paused = false
	player.play()


func stop_all_sfx() -> void:
	for player in _sfx_players:
		player.stop()
		player.stream = null


func stop_all() -> void:
	stop_music()
	stop_all_sfx()


## Volume linear: 0.0 silencia e 1.0 representa o volume original.
func set_volume(bus_name: StringName, volume: float) -> void:
	var index := _get_bus_index(bus_name)
	if index != -1:
		AudioServer.set_bus_volume_linear(index, clampf(volume, 0.0, 1.0))


func get_volume(bus_name: StringName) -> float:
	var index := _get_bus_index(bus_name)
	if index == -1:
		return 0.0
	return db_to_linear(AudioServer.get_bus_volume_db(index))


## Silencia o canal sem perder o volume configurado.
func set_muted(bus_name: StringName, muted: bool) -> void:
	var index := _get_bus_index(bus_name)
	if index != -1:
		AudioServer.set_bus_mute(index, muted)


func is_muted(bus_name: StringName) -> bool:
	var index := _get_bus_index(bus_name)
	return index != -1 and AudioServer.is_bus_mute(index)


func _get_sfx_player() -> AudioStreamPlayer:
	for player in _sfx_players:
		if not player.playing:
			# Mantém a ordem de uso para substituir o som mais antigo no limite.
			_sfx_players.erase(player)
			_sfx_players.append(player)
			return player

	if _sfx_players.size() < MAX_SFX_PLAYERS:
		var player := AudioStreamPlayer.new()
		player.name = "SfxPlayer%d" % (_sfx_players.size() + 1)
		player.bus = SFX_BUS
		add_child(player)
		player.finished.connect(_release_sfx_stream.bind(player))
		_sfx_players.append(player)
		return player

	var oldest_player: AudioStreamPlayer = _sfx_players.pop_front()
	oldest_player.stop()
	_sfx_players.append(oldest_player)
	return oldest_player


func _release_sfx_stream(player: AudioStreamPlayer) -> void:
	player.stream = null


func _set_stream_loop(stream: AudioStream, looped: bool) -> void:
	if stream is AudioStreamMP3 or stream is AudioStreamOggVorbis:
		stream.loop = looped
	elif stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD if looped else AudioStreamWAV.LOOP_DISABLED
		if looped and stream.loop_end <= stream.loop_begin:
			stream.loop_begin = 0
			stream.loop_end = roundi(stream.get_length() * stream.mix_rate)


func _get_bus_index(bus_name: StringName) -> int:
	var index := AudioServer.get_bus_index(bus_name)
	if index == -1:
		push_warning("AudioManager: canal de áudio inexistente: %s." % bus_name)
	return index
