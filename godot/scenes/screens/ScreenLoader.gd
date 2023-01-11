extends Node

var loader
var wait_frames
var time_max = 10 # msec
var current_scene
var current_path = null

func _ready():
	var root = get_tree().get_root()
	current_scene = root.get_child(root.get_child_count() -1)

func goto_scene(path): # Game requests to switch to this scene.
	current_path = path
	loader = ResourceLoader.load_interactive(path)
	if loader == null:
		printerr("Error, ScreenLoader loader is null")
		return
	set_process(true)

	wait_frames = 1

func reload_current_scene():
	if current_path == null:
		printerr("Error, ScreenLoader could not reload first Screen")
		return
	goto_scene(current_path)

func _process(time):
	if loader == null:
		# no need to process anymore
		set_process(false)
		return

	# Wait for frames to let the "loading" animation show up.
	if wait_frames > 0:
		wait_frames -= 1
		return

	var t = OS.get_ticks_msec()
	# Use "time_max" to control for how long we block this thread.
	while OS.get_ticks_msec() < t + time_max:
		# Poll your loader.
		var err = loader.poll()

		if err == ERR_FILE_EOF: # Finished loading.
			_load_done()
			break
		elif err == OK:
			_load_progress()
		else: # Error during loading.
			printerr("Error during ScreenLoader load")
			loader = null
			break

func _load_progress():
	var progress = float(loader.get_stage()) / loader.get_stage_count()

func _load_done():
	var resource = loader.get_resource()
	loader = null
	current_scene.queue_free() # Get rid of the old scene.
	_set_new_scene(resource)

func _set_new_scene(scene_resource):
	current_scene = scene_resource.instance()
	get_node("/root").add_child(current_scene)
