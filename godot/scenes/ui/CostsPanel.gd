extends Node2D

const CostsPanelLine = preload("res://scenes/ui/CostsPanelLine.tscn")

onready var child_root = $PanelContainer/VBoxContainer

func init_costs_from(inventory):
	for child in child_root.get_children():
		child.queue_free()

	for type in inventory.get_keys():
		var value = inventory.get_value(type)
		if value == 0:
			continue

		var line = CostsPanelLine.instance()
		line.item_type = type
		line.cost = value

		child_root.add_child(line)

func _on_player_inventory_changed(inventory):
	for child in child_root.get_children():
		child.update_from_player_inventory(inventory)
