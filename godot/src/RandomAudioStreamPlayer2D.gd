extends AudioStreamPlayer2D

export var sound_dir := ""


func play(from_position: float = 0.0):
	var sounds = Globals.get_sounds(sound_dir)
	if sounds.size() == 0:
		return
	
	stream = sounds[randi() % sounds.size()]
	
	.play(from_position)
