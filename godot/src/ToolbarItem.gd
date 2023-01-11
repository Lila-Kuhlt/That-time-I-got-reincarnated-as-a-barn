extends Button

class_name ToolbarItem

signal item_selected(slot_id, costs_or_null)

export var tooltip_text := ""
export var show_costs_on_hover = false
export var show_value := false setget _set_show_value

var shown_value = "Test" setget _set_shown_value
var tooltip_visible = false
var slot_id: int setget _set_slot_id

const DEFAULT_TEXTURE = 0

func _ready():
	set_item()
	icon = icon.duplicate()
	_set_shown_value(shown_value)
	_set_show_value(show_value)
	$Labels/Label.modulate = Color(1.3,1.3,1.6,1)
	if show_costs_on_hover:
		$CostsPanel.init_from($Costs)
	$TooltipPanel/PanelContainer/Label.text = tooltip_text

func _set_slot_id(v):
	slot_id = v
	$Labels/LabelHotkey.text = str(slot_id)

func set_selected(is_sel: bool) -> void:
	self.pressed = is_sel

func set_item(item_id=DEFAULT_TEXTURE):
	if not item_id in Globals.ITEM_NAMES:
		item_id = DEFAULT_TEXTURE

	var x: int = icon.region.size.y * int(Globals.ITEM_TEXTURE_LOOKUP[item_id])
	icon.region.position.x = x

func _set_shown_value(v):
	shown_value = v
	if is_inside_tree():
		$Labels/Label.text = str(v)
func _set_show_value(v):
	show_value = v
	if is_inside_tree():
		$Labels/Label.visible = v

func register_callback(toolbar):
	toolbar.connect("item_selected", self, "_on_toolbar_selection_changed")


func _on_toolbar_selection_changed(slot, _costs_or_null):
	if not tooltip_text.empty():
		if tooltip_visible and self.pressed and self.slot_id != slot:
			$AnimationPlayer.play("hide_tooltip")
			tooltip_visible = false
		if not tooltip_visible and self.slot_id == slot:
			$AnimationPlayer.play("show_tooltip")
			tooltip_visible = true
	if show_costs_on_hover:
		if tooltip_visible and self.pressed and self.slot_id != slot:
			$AnimationPlayer.play("hide_costs")
			tooltip_visible = false
		if not tooltip_visible and self.slot_id == slot:
			$AnimationPlayer.play("show_costs")
			tooltip_visible = true

	set_selected(self.slot_id == slot)

func _on_ToolbarItem_button_down():
	emit_signal("item_selected", slot_id, get_costs())

func _on_ToolbarItem_mouse_entered():
	if not tooltip_text.empty() and not tooltip_visible:
		$AnimationPlayer.play("show_tooltip")
		tooltip_visible = true
	if show_costs_on_hover and not tooltip_visible:
		$AnimationPlayer.play("show_costs")
		tooltip_visible = true

func _on_ToolbarItem_mouse_exited():
	if not tooltip_text.empty() and not self.pressed:
		$AnimationPlayer.play("hide_tooltip")
		tooltip_visible = false
	if show_costs_on_hover and tooltip_visible and not self.pressed:
		$AnimationPlayer.play("hide_costs")
		tooltip_visible = false

func _on_player_inventory_changed(inventory):
	if show_value:
		_set_shown_value(inventory.get_value(slot_id))
	if has_costs():
		disabled = not inventory.can_pay(get_costs())

func has_costs():
	return has_node("Costs")
func get_costs():
	return $Costs if has_costs() else null


func _on_ToolbarItem_toggled(button_pressed):
	$Labels.position.y = -1 if button_pressed else 0
