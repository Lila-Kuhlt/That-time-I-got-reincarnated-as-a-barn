extends Node2D

const CostsPanelLine = preload("res://scenes/ui/CostsPanelLine.tscn")

func init_from(inventory):

	var child_root = $PanelContainer/VBoxContainer

	for child in child_root.get_children():
		child.queue_free()

	for type in inventory.get_keys():
		var value = inventory.get_value(type)
		if value == 0:
			continue

		var line = CostsPanelLine.instance()
		line.item_type = type
		line.value = value

		child_root.add_child(line)
