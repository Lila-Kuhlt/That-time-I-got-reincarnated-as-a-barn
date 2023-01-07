extends HBoxContainer

var selected_item: int = 0
var selected_item_subspace: float = 0
onready var child_count := get_child_count()

func _ready():
	update_selected_item(true)

func _process(delta):
	var mouse_scroll_left := Input.is_action_just_released("scroll_left_mouse")
	var mouse_scroll_right := Input.is_action_just_released("scroll_right_mouse")
	# TODO: scrolling with joypad with different action
	#       beacause scroll buttons don't support Input.get_axis :(
	var scroll := float(mouse_scroll_right) - float(mouse_scroll_left)
	if scroll != 0:
		selected_item_subspace += scroll
		update_selected_item()
	else:
		for item in range(child_count):
			if Input.is_action_just_pressed("toolbar_item" + str(item + 1)):
				selected_item_subspace = item
				update_selected_item()
				break

func update_selected_item(force=false):
	if selected_item_subspace < 0:
		selected_item_subspace = child_count + selected_item_subspace
	elif selected_item_subspace >= child_count:
		selected_item_subspace -= child_count
	var new_selected_item: int = int(round(selected_item_subspace))
	new_selected_item %= child_count
	if !force and new_selected_item == selected_item:
		return
	selected_item = new_selected_item
	for child in range(child_count):
		get_child(child).set_selected(child == selected_item)
