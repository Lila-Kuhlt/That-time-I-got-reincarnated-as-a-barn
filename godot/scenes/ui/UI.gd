extends CanvasLayer


signal item_selected(globals_itemtype, costs_or_null)

onready var toolbar = $MarginContainer/VBoxContainer/ToolBar
onready var label_time: Label = $MarginContainer/VBoxContainer/TopMenu/LabelTime
onready var label_score: Label = $MarginContainer/VBoxContainer/TopMenu/LabelScore

func _ready():
	Globals.connect("score_changed", self, "_on_score_changed")

func _on_score_changed(v):
	label_score.text = "Score: %03d" % v
	
func _process(_delta):
	label_time.text = "Time: %03d" % Globals.get_game_time()

func _on_toolbar_item_selected(globals_itemtype, costs_or_null):
	emit_signal("item_selected", globals_itemtype, costs_or_null)

func _on_Player_player_inventory_changed(inventory):
	toolbar.update_inventory(inventory)

func _on_ButtonPause_pressed():
	$PauseMenu.try_show()

func _on_ButtonZoomIn_button_down():
	Input.action_press("zoom_in")
func _on_ButtonZoomIn_button_up():
	Input.action_release("zoom_in")
func _on_ButtonZoomOut_button_down():
	Input.action_press("zoom_out")
func _on_ButtonZoomOut_button_up():
	Input.action_release("zoom_out")
	
