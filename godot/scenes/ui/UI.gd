extends CanvasLayer


signal item_selected(globals_itemtype)

onready var toolbar = $MarginContainer/VBoxContainer/ToolBar

func _on_toolbar_item_selected(globals_itemtype):
	emit_signal("item_selected", globals_itemtype)

