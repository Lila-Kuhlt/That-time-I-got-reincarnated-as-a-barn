extends Node2D

const HOVER_ALPHA: float = 0.7

var is_currently_animating = false
var selection = null
onready var title_label = $PanelContainer/MarginContainer/VBoxContainer/Title
onready var stat_grid: GridContainer = $PanelContainer/MarginContainer/VBoxContainer/GridContainer
onready var animator: AnimationPlayer = $AnimationPlayer
onready var animator_hover: AnimationPlayer = $HoverIndicator/AnimationPlayer

const STATS_TO_SHOW = [
	["HEALTH",		"HP", "%d"],
	["ATK SPEED",	"AS", "%.1f"],
	["DAMAGE",		"DMG", "%.1f"],
	["AOE",		"AOE", "%.1f"],
	["KNOCKBACK",		"KB", "%.1f"],
	["PENETRATION",		"PEN", "%.1f"],
	["RANGE",		"RG", "%d"],
	["PROJ SPEED",		"PS", "%d"]
]

func _ready():
	pass

func _process(delta):
	pass

func construct_tower_title(tower):
	return tower.tower_name

func update_tower_stats(tower):
	# clear previous Labels
	for child in stat_grid.get_children():
		child.queue_free()
	
	# create new Labels
	for stat in STATS_TO_SHOW:
		var stat_value = tower.stats.get(stat[1])
		if stat_value == 0.0:
			continue
		
		var label_name = Label.new()
		label_name.text = stat[0]
		label_name.size_flags_horizontal = Control.SIZE_FILL | Control.SIZE_EXPAND
		
		var stat_string = stat[2] % stat_value
		
		var label_stat = Label.new()
		label_stat.text = stat_string
		label_stat.align = Label.ALIGN_RIGHT
		
		stat_grid.add_child(label_name)
		stat_grid.add_child(label_stat)
	stat_grid.size_flags_vertical = stat_grid.get_child_count()

var selected = false

func _on_World_hover_end_tower():
	animator_hover.play("hide")

func _on_World_hover_start_tower(coord, tower):
	if selected or is_currently_animating:
		return
	global_position = coord
	title_label.text = construct_tower_title(tower)

	animator_hover.play("show")

func _on_World_select_tower(coord, tower):
	selected = true
	global_position = coord
	animator.play("show")
	animator_hover.play("hide")
	title_label.text = construct_tower_title(tower)
	update_tower_stats(tower)
	

func _on_World_unselect_tower():
	selected = false
	animator.play("hide")
	is_currently_animating = true
	
func _on_AnimationPlayer_animation_finished(anim_name: String):
	if anim_name == "hide":
		is_currently_animating = false
