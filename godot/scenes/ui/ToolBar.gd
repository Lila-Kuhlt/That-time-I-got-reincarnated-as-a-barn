extends HBoxContainer

var selected_item := 0
onready var child_count := get_child_count()

func _ready():
	update_selected_item()

func _process(delta):
	pass

func update_selected_item():
	for child in range(child_count):
		get_child(child).set_selected(child == selected_item)
