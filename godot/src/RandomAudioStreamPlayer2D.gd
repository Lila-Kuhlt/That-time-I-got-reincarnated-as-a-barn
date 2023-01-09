extends AudioStreamPlayer2D

export var sound_dir := ""

var sounds = []
var is_on_build := false

func _ready():
	if sound_dir == "":
		return
		
	is_on_build = OS.has_feature("standalone")
	
	sounds = []
	
	var dir = Directory.new()
	if dir.open(sound_dir) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				# Differentiate whether on export or debug
				if is_on_build:
					if file_name.ends_with('.import'):  
						file_name = file_name.replace('.import', '')
						if file_name.ends_with(".wav"):
							sounds.append(load(sound_dir + "/" + file_name))
				else:
					if file_name.ends_with(".wav"):
						sounds.append(load(sound_dir + "/" + file_name))

			file_name = dir.get_next()
	else:
		printerr("Could not open sound dir ", sound_dir)

func play(from_position: float = 0.0):
	if sounds.size() == 0:
		return
	
	stream = sounds[randi() % sounds.size()]
	
	.play(from_position)
