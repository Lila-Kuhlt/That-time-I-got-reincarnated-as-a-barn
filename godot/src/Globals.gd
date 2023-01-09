extends Node

### GAME LOSE
signal game_lost
func _ready():
	connect("game_lost", self, "_on_game_lost")
func _on_game_lost():
	yield(get_tree(), "idle_frame")
	score = 0
	curr_enemies = 0
	
### ENEMIES
const MAX_ENEMIES = 30
export var curr_enemies: int = 0 setget _set_curr_enemies

func _set_curr_enemies(val: int):
	curr_enemies = int(max(0, val))

func can_spawn_enemy() -> bool:
	return curr_enemies < MAX_ENEMIES
	
### SCORE
signal score_changed(new_score)
var score = 0
func add_score(score_delta):
	score += score_delta
	emit_signal("score_changed", score)
func get_score():
	return score

### GAME TIME
onready var game_start_time = OS.get_ticks_msec()
func get_game_time():
	return (OS.get_ticks_msec() - game_start_time) / 1000.0

### SOUND SINGLETON
var _sounds_singleton = {}
func get_sounds(sound_dir):
	if not _sounds_singleton.has(sound_dir):
		_sounds_singleton[sound_dir] = _load_sounds(sound_dir)
	return _sounds_singleton[sound_dir]

var is_on_build := false
func _load_sounds(sound_dir):
	if sound_dir == "":
		return []
		
	is_on_build = OS.has_feature("standalone")
	
	var sounds = []
	
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
	
	return sounds
		

enum Direction {
	None,
	Left,
	Right,
	Up,
	Down
}

enum EnemyType {
	Rabbit,
	Racoon,
	Ant
}

enum GrowState {
	Seedling = 0,
	Growing = 1,
	Grown = 2,
	Rotten = 3
}

enum ItemType {
	None
	ToolScythe,
	ToolWateringCan,
	PlantChili,
	PlantTomato,
	PlantPotato,
	PlantAubergine,
	TowerWindmill,
	TowerWatertower,
	TowerWIP
}

const ITEM_NAMES = {
	# Items
	ItemType.ToolScythe : "Scythe",
	ItemType.ToolWateringCan : "Watering Can",

	# Plants
	ItemType.PlantChili : "Chili",
	ItemType.PlantTomato : "Tomato",
	ItemType.PlantAubergine : "Aubergine",
	ItemType.PlantPotato : "Potato",

	# Towers
	ItemType.TowerWindmill : "Windmill",
	ItemType.TowerWatertower : "Watertower",
	ItemType.TowerWIP : "WIP"
}

const TOOLS = [
	ItemType.ToolScythe,
	ItemType.ToolWateringCan
]

const PLANTS = [
	ItemType.PlantChili,
	ItemType.PlantTomato,
	ItemType.PlantAubergine,
	ItemType.PlantPotato
]

const TOWERS = [
	ItemType.TowerWindmill,
	ItemType.TowerWatertower,
	ItemType.TowerWIP
]

var ITEM_TEXTURE_LOOKUP = {
	ItemType.None : 0,
	
	# Items
	ItemType.ToolScythe : 1,
	ItemType.ToolWateringCan : 2,

	#Plants
	ItemType.PlantChili : 3,
	ItemType.PlantTomato : 4,
	ItemType.PlantPotato : 5,
	ItemType.PlantAubergine : 6,

	# Towers
	ItemType.TowerWindmill : 7,
	ItemType.TowerWatertower : 8,
	ItemType.TowerWIP : 9
}

const tower_hitbox_size = 17
