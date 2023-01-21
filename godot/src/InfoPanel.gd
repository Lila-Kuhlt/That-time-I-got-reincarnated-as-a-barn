extends Node2D

onready var title_label = $PanelContainer/MarginContainer/VBoxContainer/Title
onready var stat_grid: GridContainer = $PanelContainer/MarginContainer/VBoxContainer/GridContainer
onready var animator: AnimationPlayer = $AnimationPlayer
onready var animator_hover: AnimationPlayer = $HoverIndicator/AnimationPlayer

var animation_state_queue := []
var current_animation_state: AnimationState = null
var hovering = null
var selection = null

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
	$PanelContainer.visible = false

func _process(delta):
	# Check if current animation state signifies completion
	if current_animation_state != null:
		if current_animation_state.is_done:
			current_animation_state.leave()
			current_animation_state = null
		
	# if so: check if Animation state waiting in queue
	if current_animation_state == null:
		if animation_state_queue.size() > 0:
			var animation_state: AnimationState = animation_state_queue.pop_front()
			
			# Check if the state wants to replace itself
			var animation_state_replace = animation_state.before_enter()
			# null  : enter state normally
			# false : don't enter at all
			# object: enter object instead
			
			if not animation_state_replace is bool:
				current_animation_state = animation_state if animation_state_replace == null else animation_state_replace
				current_animation_state.enter()

## SIGNAL REDIRECTS
func _on_AnimationPlayer_animation_finished(anim_name: String):
	if current_animation_state != null:
		current_animation_state._on_animator_finished(anim_name)
	
func _on_AnimationPlayerHover_animation_finished(anim_name: String):
	if current_animation_state != null:
		current_animation_state._on_animator_hover_finished(anim_name)
	
func _on_World_hover_start_tower(tower, snap_pos):
	animation_state_queue.push_back(AnimationStateHoverStart.new(self, tower, snap_pos))

func _on_World_hover_end_tower(tower, snap_pos):
	animation_state_queue.push_back(AnimationStateHoverEnd.new(self, tower, snap_pos))

func _on_World_select_tower(tower, snap_pos):
	animation_state_queue.push_back(AnimationStateSelect.new(self, tower, snap_pos))

func _on_World_unselect_tower(tower, snap_pos):
	animation_state_queue.push_back(AnimationStateUnselect.new(self, tower, snap_pos))

## UPDATING INFO PANEL CONTROLS

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
		label_name.theme_type_variation = "LabelSmall"
		label_name.text = stat[0]
		label_name.size_flags_horizontal = Control.SIZE_FILL | Control.SIZE_EXPAND

		var stat_string = stat[3] % stat_value

		var label_stat = Label.new()
		label_stat.theme_type_variation = "LabelSmall"
		label_stat.text = stat_string
		label_stat.align = Label.ALIGN_RIGHT

		stat_grid.add_child(label_name)
		stat_grid.add_child(label_stat)

	$PanelContainer.emit_signal("resized")

	yield(get_tree(), "idle_frame")
	$PanelContainer.rect_size.y = 0

func _on_tower_stats_updated(tower):
	update_tower_stats(tower)

func _on_tower_health_changed(health, max_health):
	$PanelContainer/MarginContainer/VBoxContainer/ProgressBar.value = 100 * health / max_health
	$PanelContainer/MarginContainer/VBoxContainer/ProgressBar/Label.text = "%d/%d" % [health, max_health]

func divide_by_32(v: float) -> float:
	return v / 32

## TOWER SIGNALS
func connect_tower_signals(tower):
	# initial update
	title_label.text = tower.tower_name
	update_tower_stats(tower)
	_on_tower_health_changed(tower.health, tower.max_health)
	# then update on signals
	tower.connect("stats_updated", self, "_on_tower_stats_updated")
	tower.connect("health_changed", self, "_on_tower_health_changed")
func disconnect_tower_signals(tower):
	if is_instance_valid(tower):
		if tower.is_connected("health_changed", self, "_on_tower_health_changed"):
			tower.disconnect("health_changed", self, "_on_tower_health_changed")
		if tower.is_connected("stats_updated", self, "_on_tower_stats_updated"):
			tower.disconnect("stats_updated", self, "_on_tower_stats_updated")
			
## ANIMATION STATES

class AnimationState:
	var parent
	var tower
	var snap_pos: Vector2
	var is_done = false
	func _init(parent, tower, snap_pos: Vector2):
		self.parent = parent
		self.tower = tower
		self.snap_pos = snap_pos
	
	# OVERRIDES
	func before_enter(): pass
	func enter(): pass
	func leave(): pass
	func _on_animator_finished(anim_name: String): pass
	func _on_animator_hover_finished(anim_name: String): pass

class AnimationStateHoverStart extends AnimationState:
	func _init(parent, tower, snap_pos: Vector2).(parent, tower, snap_pos):
		pass
	func enter():
		if parent.selection != null:
			parent.disconnect_tower_signals(parent.selection)
			parent.selection = tower
			parent.connect_tower_signals(parent.selection)
		parent.hovering = tower
		parent.global_position = snap_pos
		parent.animator_hover.play("show")
	func leave():
		parent.animator_hover.play("wiggle")
	func _on_animator_hover_finished(anim_name: String):
		if anim_name == "show":
			is_done = true

class AnimationStateHoverEnd extends AnimationState:
	func _init(parent, tower, snap_pos: Vector2).(parent, tower, snap_pos):
		pass
	func enter():
		parent.animator_hover.play("hide")
	func leave():
		parent.hovering = null
	func _on_animator_hover_finished(anim_name: String):
		if anim_name == "hide":
			is_done = true

class AnimationStateSelect extends AnimationState:
	func _init(parent, tower, snap_pos: Vector2).(parent, tower, snap_pos):
		pass
	func before_enter():
		if parent.selection != null:
			return AnimationStateUnselect.new(parent, tower, snap_pos)
		return null
	func enter():
		parent.selection = tower
		parent.global_position = snap_pos
		parent.animator.play("show")

		parent.connect_tower_signals(tower)
	func _on_animator_finished(anim_name: String):
		if anim_name == "show":
			is_done = true

class AnimationStateUnselect extends AnimationState:
	func _init(parent, tower, snap_pos: Vector2).(parent, tower, snap_pos):
		pass
	func before_enter():
		if parent.selection != tower:
			return false
		return null
	func enter():
		parent.animator.play("hide")
	func leave():
		parent.selection = null
		parent.disconnect_tower_signals(tower)
	func _on_animator_finished(anim_name: String):
		if anim_name == "hide":
			is_done = true
