extends Button

class_name ToolbarItem

signal item_selected(slot_id, costs_or_null)

export var show_costs_on_hover = false
export var show_value = false setget _set_show_value
var shown_value = "Test" setget _set_shown_value

var slot_id: int

const DEFAULT_TEXTURE = 0

func _ready():
	set_item()
	icon = icon.duplicate()
	_set_shown_value(shown_value)
	_set_show_value(show_value)
	
	if show_costs_on_hover:
		$CostsPanel.init_from($Costs)

func set_selected(is_sel: bool) -> void:
	self.pressed = is_sel

func set_item(item_id=DEFAULT_TEXTURE):
	if not item_id in Globals.ITEM_NAMES:
		item_id = DEFAULT_TEXTURE

	var x: int = icon.region.size.y * int(Globals.ITEM_TEXTURE_LOOKUP[item_id])
	icon.region.position.x = x
	
func _set_shown_value(v):
	shown_value = v
	$Label.text = str(v)
func _set_show_value(v):
	show_value = v
	$Label.visible = v

func register_callback(toolbar):
	toolbar.connect("item_selected", self, "_on_toolbar_selection_changed")

func _on_toolbar_selection_changed(slot, _costs_or_null):
	set_selected(self.slot_id == slot)

func _on_ToolbarItem_button_down():
	emit_signal("item_selected", slot_id, get_costs())

func _on_ToolbarItem_mouse_entered():
	if show_costs_on_hover:
		$AnimationPlayer.play("show_costs")

func _on_ToolbarItem_mouse_exited():
	if show_costs_on_hover:
		$AnimationPlayer.play("hide_costs")

func _on_player_inventory_changed(inventory):
	if show_value:
		_set_shown_value(inventory.get_value(slot_id))
	if has_costs():
		disabled = not inventory.can_pay(get_costs())

func has_costs():
	return has_node("Costs")
func get_costs():
	return $Costs if has_costs() else null
