# MusicManager.gd
extends Node
## Verwaltet das Abspielen der Hintergrundmusik.

var _music_player: AudioStreamPlayer


func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	add_child(_music_player)

	var stream = load("res://assets/audio/background_music.ogg")
	if stream:
		_music_player.stream = stream
		if _music_player.stream is AudioStreamOggVorbis:
			_music_player.stream.loop = true
		_music_player.play()
