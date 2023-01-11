extends Node2D

const HOVER_ALPHA: float = 0.7

var is_currently_animating = false
var selection = null
onready var title_label = $PanelContainer/MarginContainer/VBoxContainer/Title
onready var stat_grid: GridContainer = $PanelContainer/MarginContainer/VBoxContainer/GridContainer
onready var animator: AnimationPlayer = $AnimationPlayer
onready var animator_hover: AnimationPlayer = $HoverIndicator/AnimationPlayer

const STATS_TO_SHOW = [
	["ATK SPEED",		"AS", null, "%.1f"],
	["DAMAGE",			"DMG", null, "%.1f"],
	["AOE",				"AOE", null, "%.1f"],
	["KNOCKBACK",		"KB", null, "%.1f"],
	["PENETRATION",		"PEN", null, "%.1f"],
	["RANGE",			"RG", "divide_by_32", "%.1f"],
	["PROJ SPEED",		"PS", null, "%d"]
]

func _ready():
	pass

func divide_by_32(v: float) -> float:
	return v / 32

func _process(_delta):
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

		# If defined: dynamically call fct by string (Lambda für Arme)
		var fct = stat[2]
		if fct != null:
			stat_value = call(fct, stat_value)

		var label_name = Label.new()
		label_name.text = stat[0]
		label_name.size_flags_horizontal = Control.SIZE_FILL | Control.SIZE_EXPAND

		var stat_string = stat[3] % stat_value

		var label_stat = Label.new()
		label_stat.text = stat_string
		label_stat.align = Label.ALIGN_RIGHT

		stat_grid.add_child(label_name)
		stat_grid.add_child(label_stat)

	$PanelContainer.emit_signal("resized")

	yield(get_tree(), "idle_frame")
	$PanelContainer.rect_size.y = 0


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
	selection = tower
	global_position = coord
	animator.play("show")
	animator_hover.play("hide")
	title_label.text = construct_tower_title(tower)

	update_tower_stats(tower)
	_on_tower_health_changed(tower.health, tower.max_health)

	tower.connect("stats_updated", self, "_on_tower_stats_updated")
	tower.connect("health_changed", self, "_on_tower_health_changed")

func _on_tower_stats_updated(tower):
	update_tower_stats(tower)
func _on_tower_health_changed(health, max_health):
	$PanelContainer/MarginContainer/VBoxContainer/ProgressBar.value = 100 * health / max_health
	$PanelContainer/MarginContainer/VBoxContainer/ProgressBar/Label.text = "%d/%d" % [health, max_health]

func _on_World_unselect_tower():
	if is_instance_valid(selection):
		if selection.is_connected("health_changed", self, "_on_tower_health_changed"):
			selection.disconnect("health_changed", self, "_on_tower_health_changed")
		if selection.is_connected("stats_updated", self, "_on_tower_stats_updated"):
			selection.disconnect("stats_updated", self, "_on_tower_stats_updated")

	selected = false
	animator.play("hide")
	is_currently_animating = true

func _on_AnimationPlayer_animation_finished(anim_name: String):
	if anim_name == "hide":
		is_currently_animating = false
