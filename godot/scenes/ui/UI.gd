extends CanvasLayer


signal item_selected(globals_itemtype, costs_or_null)

onready var toolbar = $MarginContainer/VBoxContainer/ToolBar

func _on_toolbar_item_selected(globals_itemtype, costs_or_null):
	emit_signal("item_selected", globals_itemtype, costs_or_null)

func _on_Player_player_inventory_changed(inventory):
	toolbar.update_inventory(inventory)

func _on_ButtonPause_pressed():
	$PauseMenu.try_show()
