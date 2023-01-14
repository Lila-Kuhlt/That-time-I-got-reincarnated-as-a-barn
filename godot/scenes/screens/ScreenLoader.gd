extends Node

var _loader
var _time_max = 80 # msec
var _current_scene
var _current_path = null
var _wait_frames = 1
var _done_loading = false

const ScreenTransition = preload("res://scenes/screens/ScreenTransition.tscn")
onready var screenTransition = ScreenTransition.instance()

func _ready():
	var root = get_tree().get_root()
	_current_scene = root.get_child(root.get_child_count() - 1)
	# Add Transition screen in next frame, since root not yet ready
	root.call_deferred("add_child", screenTransition)

func goto_scene(path, free_current_screen_immediately = false):
	_current_path = path
	_loader = ResourceLoader.load_interactive(_current_path)
	if _loader == null:
		printerr("Error, ScreenLoader loader is null")
		return

	screenTransition.transitionStart(free_current_screen_immediately)
	if free_current_screen_immediately:
		_current_scene.queue_free()
		_current_scene = null

	set_process(true)
	_wait_frames = 1
	_done_loading = false

func reload_current_scene(free_current_screen_immediately = false):
	if _current_path == null:
		printerr("Error, ScreenLoader could not reload first Screen")
		return
	goto_scene(_current_path, free_current_screen_immediately)

func _process(time):
	if _done_loading:
		_load_done()
		return

	if _loader == null:
		# no need to process anymore
		set_process(false)
		return

	# Wait for frames to let the "loading" animation show up.
	if _wait_frames > 0:
		_wait_frames -= 1
		return

	var t = Time.get_ticks_msec()
	# Use "time_max" to control for how long we block this thread.
	while Time.get_ticks_msec() < t + _time_max:
		# Poll your loader.
		var err = _loader.poll()

		if err == ERR_FILE_EOF: # Finished loading.
			_load_progress()
			_done_loading = true
			break
		elif err == OK:
			_load_progress()
		else: # Error during loading.
			printerr("Error during ScreenLoader load")
			_loader = null
			break

func _load_progress():
	var progress = float(_loader.get_stage()) / _loader.get_stage_count()
	screenTransition.transitionProgress(progress)

func _load_done():
	var resource = _loader.get_resource()
	_loader = null
	screenTransition.transitionEnd()
	if _current_scene != null:
		_current_scene.queue_free()
	_set_new_scene(resource)
	_done_loading = false

func _set_new_scene(scene_resource):
	_current_scene = scene_resource.instance()
	get_node("/root").add_child(_current_scene)
